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
  final Set<VoidCallback> _listeners = {};
  final Set<SignalObserver> _observers = {};
  final bool Function(T, T)? _equals;
  bool _isDisposed = false;

  // Time Travel / History
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
    if (_currentObserver != null) {
      _observers.add(_currentObserver!);
    }
    return _value;
  }

  set value(T newValue) {
    // Use custom equality comparator if provided, otherwise use ==
    final isEqual =
        _equals != null ? _equals(_value, newValue) : _value == newValue;
    if (isEqual) return;

    Transaction.current?.record(this, _value);

    final oldValue = _value;
    _value = newValue;

    if (enableHistory) {
      // Truncate forward history if we branched
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
    if (_isDisposed) return;
    for (final listener in _listeners.toList()) {
      listener();
    }
    for (final observer in _observers.toList()) {
      observer.onDependencyChanged();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
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
  final Set<VoidCallback> _listeners = {};
  final Set<SignalObserver> _observers = {};
  // Track source signals so we can unsubscribe
  final Set<Signal<dynamic>> _sources = {};

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

    if (_currentObserver != null) {
      _observers.add(_currentObserver!);
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
    for (final listener in _listeners.toList()) {
      listener();
    }
    for (final observer in _observers.toList()) {
      observer.onDependencyChanged();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    // If no more listeners, unsubscribe from all source signals
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

Effect effect(void Function() fn) {
  return Effect(fn);
}
