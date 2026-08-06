part of 'signal.dart';

class StateSignal<T> implements Signal<T>, Disposable {
  T _value;

  // Separate listener lists for UI callbacks and reactive observers.
  // We store them separately so the hot-path for pure listeners (no computed
  // children) doesn't pay the cost of iterating an empty observers list.
  final List<VoidCallback> _listeners = [];
  final List<SignalObserver> _observers = [];

  final bool Function(T, T)? _equals;
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

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
    if (_isDisposed) throw StateError('$runtimeType has been disposed');
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

  @override
  String toString() => 'StateSignal(value: $_value)';

  set value(T newValue) {
    if (_isDisposed) throw StateError('$runtimeType has been disposed');
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
    if (_isDisposed) throw StateError('$runtimeType has been disposed');
    if (!enableHistory || _historyIndex <= 0) return;
    _historyIndex--;
    setValueWithoutRecording(_history[_historyIndex]);
  }

  void redo() {
    if (_isDisposed) throw StateError('$runtimeType has been disposed');
    if (!enableHistory || _historyIndex >= _history.length - 1) return;
    _historyIndex++;
    setValueWithoutRecording(_history[_historyIndex]);
  }

  List<T> get history => List.unmodifiable(_history);

  void update(T Function(T) updater) {
    if (_isDisposed) throw StateError('$runtimeType has been disposed');
    value = updater(_value);
  }

  void _notify() {
    if (_isDisposed) return;

    final tx = Transaction.current;
    if (tx != null && !tx.isCommitting) {
      // Immediate invalidation of downstream computeds so reads are accurate
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

  /// Number of active reactive observers (effects/computed) on this signal.
  /// Exposed for testing to verify zero memory retention after dispose.
  @visibleForTesting
  int get observerCount => _observers.length;

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _listeners.clear();
    _observers.clear();
    _history.clear();
    _deferredUpdates.clear();
  }
}
