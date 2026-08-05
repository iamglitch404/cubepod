import 'package:cubepod_core/cubepod_core.dart';
import 'package:meta/meta.dart';
import 'transaction.dart';
import 'dart:async';

// ─────────────────────────────────────────────────────────────────────────────
// GLOBAL SIGNAL CONFIGURATION
// Provides a pluggable error handler so host apps can route signal exceptions
// to Sentry, Firebase Crashlytics, or a custom logger.
// ─────────────────────────────────────────────────────────────────────────────

/// Global configuration for the CubePod state engine.
///
/// Set [errorHandler] to intercept and log errors that occur inside listener
/// callbacks or effect bodies without crashing the application.
///
/// ```dart
/// SignalConfig.errorHandler = (error, stack) {
///   Sentry.captureException(error, stackTrace: stack);
/// };
/// ```
class SignalConfig {
  SignalConfig._();

  /// Called whenever an exception occurs inside a listener callback, observer
  /// notification, or effect body. Defaults to forwarding to the current
  /// [Zone]'s uncaught error handler (same as `FlutterError.onError` in a
  /// running Flutter app).
  static void Function(Object error, StackTrace stack) errorHandler =
      (error, stack) => Zone.current.handleUncaughtError(error, stack);
}

// ─────────────────────────────────────────────────────────────────────────────
// ABSTRACT INTERFACES
// ─────────────────────────────────────────────────────────────────────────────

abstract class Signal<T> {
  T get value;
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
  void removeObserver(SignalObserver observer);
  void dispose();
}

typedef VoidCallback = void Function();

// Thread-local (Dart-isolate-local) current observer, used for automatic
// dependency tracking during computed/effect evaluation.
SignalObserver? _currentObserver;

int _signalIdCounter = 0;

abstract class SignalObserver {
  void onDependencyChanged();
  void trackDependency(Signal<dynamic> signal);
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE SIGNAL
// ─────────────────────────────────────────────────────────────────────────────

class StateSignal<T> implements Signal<T>, Disposable {
  T _value;

  // Separate listener lists for UI callbacks and reactive observers.
  // We store them separately so the hot-path for pure listeners (no computed
  // children) doesn't pay the cost of iterating an empty observers list.
  final List<VoidCallback> _listeners = [];
  final List<SignalObserver> _observers = [];

  final bool Function(T, T)? _equals;
  bool _isDisposed = false;

  // Re-entrancy guard: set to true while _notify() is executing.
  // If a listener writes back to this signal, the update is queued here and
  // processed immediately after the current notification loop finishes.
  bool _isNotifying = false;
  final List<T> _deferredUpdates = [];

  // Time travel (opt-in via enableHistory)
  final bool enableHistory;
  final List<T> _history = [];
  int _historyIndex = -1;
  final String _id = (_signalIdCounter++).toString();

  StateSignal(
    this._value, {
    this.enableHistory = false,
    bool Function(T, T)? equals,
  }) : _equals = equals {
    CubeDevToolsObserver.instance?.onSignalCreated(_id, _value);
    if (enableHistory) {
      _history.add(_value);
      _historyIndex = 0;
    }
  }

  @override
  T get value {
    // Auto-track dependency if we are currently inside a computed/effect.
    final observer = _currentObserver;
    if (observer != null) {
      if (!_observers.contains(observer)) {
        _observers.add(observer);
      }
      observer.trackDependency(this);
    }
    return _value;
  }

  set value(T newValue) {
    final isEqual =
        _equals != null ? _equals(_value, newValue) : _value == newValue;
    if (isEqual) return;

    if (_isNotifying) {
      // Re-entrancy guard: queue the update so it is processed cleanly after
      // the current notification pass finishes — never drop it silently.
      _deferredUpdates.add(newValue);
      return;
    }

    _applyValue(newValue);
  }

  void _applyValue(T newValue) {
    Transaction.current?.record(this, _value);

    final oldValue = _value;
    _value = newValue;

    if (enableHistory) {
      if (_historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      _history.add(_value);
      _historyIndex++;
    }

    CubeDevToolsObserver.instance?.onSignalUpdated(_id, newValue, oldValue);
    _notify();
  }

  /// Update the value without recording to the transaction log.
  /// Used internally by Transaction.rollback() and time-travel undo/redo.
  void setValueWithoutRecording(T newValue) {
    final oldValue = _value;
    _value = newValue;
    CubeDevToolsObserver.instance?.onSignalUpdated(_id, newValue, oldValue);
    _notify();
  }

  void undo() {
    if (!enableHistory || _historyIndex <= 0) return;
    _historyIndex--;
    setValueWithoutRecording(_history[_historyIndex]);
  }

  void redo() {
    if (!enableHistory || _historyIndex >= _history.length - 1) return;
    _historyIndex++;
    setValueWithoutRecording(_history[_historyIndex]);
  }

  List<T> get history => List.unmodifiable(_history);

  void update(T Function(T) updater) {
    value = updater(_value);
  }

  void _notify() {
    if (_isDisposed) return;
    _isNotifying = true;

    // Snapshot both lists before iterating. This guarantees that:
    //  - A listener removing itself mid-loop does not cause a RangeError.
    //  - A listener adding a new listener does not cause infinite iteration.
    final activeListeners = _listeners.toList(growable: false);
    for (final listener in activeListeners) {
      if (_isDisposed) break;
      try {
        listener();
      } catch (e, stack) {
        // Isolate the exception so a single broken listener cannot halt the
        // notification loop or corrupt engine state.
        SignalConfig.errorHandler(e, stack);
      }
    }

    final activeObservers = _observers.toList(growable: false);
    for (final observer in activeObservers) {
      if (_isDisposed) break;
      try {
        observer.onDependencyChanged();
      } catch (e, stack) {
        SignalConfig.errorHandler(e, stack);
      }
    }

    _isNotifying = false;

    // Flush any updates that were queued by listeners writing back to this
    // signal during the notification pass (re-entrant writes).
    if (_deferredUpdates.isNotEmpty) {
      final nextValue = _deferredUpdates.removeAt(0);
      _applyValue(nextValue);
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  void removeObserver(SignalObserver observer) {
    _observers.remove(observer);
  }

  /// Number of active reactive observers (effects/computed) on this signal.
  /// Exposed for testing to verify zero memory retention after dispose.
  @visibleForTesting
  int get observerCount => _observers.length;

  @override
  void dispose() {
    _isDisposed = true;
    _listeners.clear();
    _observers.clear();
    _history.clear();
    _deferredUpdates.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPUTED SIGNAL
// ─────────────────────────────────────────────────────────────────────────────

/// A lazily-evaluated, memoized derived signal.
///
/// The computation is re-run only when one of its tracked upstream signals
/// changes. Cache hits return the stored value with zero recomputation cost.
class ComputedSignal<T> implements Signal<T>, SignalObserver {
  final T Function() _compute;
  late T _cachedValue;
  bool _isStale = true;
  bool _isDisposed = false;

  final List<VoidCallback> _listeners = [];
  final List<SignalObserver> _observers = [];

  // The set of all upstream signals we track. Populated during each evaluation
  // pass. On dispose, we proactively unregister from every parent to ensure
  // zero memory retention.
  final Set<Signal<dynamic>> _trackedDependencies = {};

  ComputedSignal(this._compute);

  @override
  T get value {
    if (_isStale) {
      final prevObserver = _currentObserver;
      _currentObserver = this;
      try {
        _cachedValue = _compute();
      } finally {
        // Always restore the outer observer — even if _compute() throws — so
        // dependency tracking for the caller is not permanently corrupted.
        _currentObserver = prevObserver;
      }
      _isStale = false;
    }

    // Propagate upward if we are nested inside another computed/effect.
    final observer = _currentObserver;
    if (observer != null) {
      if (!_observers.contains(observer)) {
        _observers.add(observer);
      }
      observer.trackDependency(this);
    }

    return _cachedValue;
  }

  @override
  void trackDependency(Signal<dynamic> signal) {
    _trackedDependencies.add(signal);
  }

  @override
  void onDependencyChanged() {
    if (_isDisposed || !_isStale) {
      _isStale = true;
      _notify();
    }
  }

  void _notify() {
    if (_isDisposed) return;

    final activeListeners = _listeners.toList(growable: false);
    for (final listener in activeListeners) {
      try {
        listener();
      } catch (e, stack) {
        SignalConfig.errorHandler(e, stack);
      }
    }

    final activeObservers = _observers.toList(growable: false);
    for (final observer in activeObservers) {
      try {
        observer.onDependencyChanged();
      } catch (e, stack) {
        SignalConfig.errorHandler(e, stack);
      }
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  void removeObserver(SignalObserver observer) {
    _observers.remove(observer);
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Proactively unregister from every upstream dependency to ensure this
    // ComputedSignal is garbage-collected even if the upstream signals live on.
    for (final dep in _trackedDependencies) {
      dep.removeObserver(this);
    }
    _trackedDependencies.clear();
    _listeners.clear();
    _observers.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EFFECT
// ─────────────────────────────────────────────────────────────────────────────

/// Runs [fn] immediately and re-runs it whenever any of its tracked signal
/// dependencies change.
///
/// Call [dispose] to stop all re-runs and release all upstream references.
class Effect implements SignalObserver {
  final void Function() _effect;
  bool _isDisposed = false;

  // Every signal accessed during the last run is tracked here. On each re-run,
  // the set is cleared and rebuilt from scratch so stale dependencies are
  // automatically pruned (avoids phantom subscriptions).
  final Set<Signal<dynamic>> _dependencies = {};

  Effect(this._effect) {
    _run();
  }

  void _run() {
    if (_isDisposed) return;

    // Unregister from all previous dependencies before re-tracking.
    // This prunes signals that are no longer accessed in the new run.
    for (final dep in _dependencies) {
      dep.removeObserver(this);
    }
    _dependencies.clear();

    final prevObserver = _currentObserver;
    _currentObserver = this;
    try {
      _effect();
    } catch (e, stack) {
      // Forward to the configurable handler — exceptions in effects should
      // never be silent, and should never prevent future re-runs.
      SignalConfig.errorHandler(e, stack);
    } finally {
      // Always restore outer observer, even on exception.
      _currentObserver = prevObserver;
    }
  }

  @override
  void trackDependency(Signal<dynamic> signal) {
    _dependencies.add(signal);
  }

  @override
  void onDependencyChanged() {
    if (!_isDisposed) _run();
  }

  void dispose() {
    _isDisposed = true;
    // Proactively remove this effect from every upstream signal's observer list
    // so the effect is immediately eligible for garbage collection.
    for (final dep in _dependencies) {
      dep.removeObserver(this);
    }
    _dependencies.clear();
  }
}

/// Convenience constructor for creating an [Effect].
///
/// Returns the [Effect] instance so it can be disposed later.
Effect effect(void Function() fn) => Effect(fn);
