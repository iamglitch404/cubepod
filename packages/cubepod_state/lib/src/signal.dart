import 'package:cubepod_core/cubepod_core.dart';
import 'transaction.dart';

abstract class Signal<T> {
  T get value;
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
  void dispose();
}

typedef VoidCallback = void Function();

SignalObserver? _currentObserver;

int _signalIdCounter = 0;

abstract class SignalObserver {
  void onDependencyChanged();
}

class StateSignal<T> implements Signal<T>, Disposable {
  T _value;

  // Use a plain List instead of Set — for small counts (< ~20 listeners)
  // a List is faster due to memory locality and no hashing overhead.
  // We track separately for O(1) dedup on add.
  final List<VoidCallback> _listeners = [];
  final List<SignalObserver> _observers = [];

  final bool Function(T, T)? _equals;
  bool _isDisposed = false;
  bool _isNotifying = false; // re-entrancy guard

  // Time travel
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
    // Only pay the observer cost if something is actually tracking us.
    final observer = _currentObserver;
    if (observer != null && !_observers.contains(observer)) {
      _observers.add(observer);
    }
    return _value;
  }

  set value(T newValue) {
    final isEqual =
        _equals != null ? _equals(_value, newValue) : _value == newValue;
    if (isEqual) return;

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
    if (_isDisposed || _isNotifying) return;
    _isNotifying = true;

    // Iterate directly — no .toList() copy needed because we guard re-entrancy.
    final listenerCount = _listeners.length;
    for (var i = 0; i < listenerCount; i++) {
      _listeners[i]();
    }

    final observerCount = _observers.length;
    for (var i = 0; i < observerCount; i++) {
      _observers[i].onDependencyChanged();
    }

    _isNotifying = false;
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
  void dispose() {
    _isDisposed = true;
    _listeners.clear();
    _observers.clear();
    _history.clear();
  }
}

class ComputedSignal<T> implements Signal<T>, SignalObserver {
  final T Function() _compute;
  late T _cachedValue;
  bool _isStale = true;
  bool _isDisposed = false;
  final List<VoidCallback> _listeners = [];
  final List<SignalObserver> _observers = [];
  final List<Signal<dynamic>> _sources = [];

  ComputedSignal(this._compute);

  @override
  T get value {
    if (_isStale) {
      final prevObserver = _currentObserver;
      _currentObserver = this;
      _cachedValue = _compute();
      _currentObserver = prevObserver;
      _isStale = false;
    }

    final observer = _currentObserver;
    if (observer != null && !_observers.contains(observer)) {
      _observers.add(observer);
    }

    return _cachedValue;
  }

  @override
  void onDependencyChanged() {
    if (!_isStale) {
      _isStale = true;
      _notify();
    }
  }

  void _notify() {
    if (_isDisposed) return;
    final listenerCount = _listeners.length;
    for (var i = 0; i < listenerCount; i++) {
      _listeners[i]();
    }
    final observerCount = _observers.length;
    for (var i = 0; i < observerCount; i++) {
      _observers[i].onDependencyChanged();
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
    if (_listeners.isEmpty) {
      for (final source in _sources) {
        source.removeListener(_onSourceChanged);
      }
      _sources.clear();
    }
  }

  void _onSourceChanged() => onDependencyChanged();

  @override
  void dispose() {
    _isDisposed = true;
    _listeners.clear();
    _observers.clear();
    _sources.clear();
  }
}

class Effect implements SignalObserver {
  final void Function() _effect;
  bool _isDisposed = false;

  Effect(this._effect) {
    _run();
  }

  void _run() {
    if (_isDisposed) return;
    final prevObserver = _currentObserver;
    _currentObserver = this;
    _effect();
    _currentObserver = prevObserver;
  }

  @override
  void onDependencyChanged() {
    if (!_isDisposed) _run();
  }

  void dispose() {
    _isDisposed = true;
  }
}

Effect effect(void Function() fn) => Effect(fn);
