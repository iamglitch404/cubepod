part of 'signal.dart';

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
    if (_isDisposed) throw StateError('$runtimeType has been disposed');
    if (_isStale) {
      for (final dep in _trackedDependencies) {
        dep.removeObserver(this);
      }
      _trackedDependencies.clear();

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
  bool get requiresImmediateInvalidation => true;

  @override
  String toString() {
    if (_isStale) return 'ComputedSignal(value: <stale>)';
    return 'ComputedSignal(value: $_cachedValue)';
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

    final tx = Transaction.current;
    if (tx != null && !tx.isCommitting) {
      final activeObservers = _observers.toList(growable: false);
      for (final observer in activeObservers) {
        if (_isDisposed) break;
        if (observer.requiresImmediateInvalidation) {
          try {
            observer.onDependencyChanged();
          } catch (e, stack) {
            SignalConfig.errorHandler(e, stack);
          }
        } else {
          tx.deferObserver(observer);
        }
      }
      for (final listener in _listeners) {
        tx.deferListener(listener);
      }
      return;
    }

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

  void notifyDeferred() {
    _notify();
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
    if (_isDisposed) return;
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
