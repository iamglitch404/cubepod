import 'scope.dart';
import '../observability/observer.dart';

typedef FactoryFunc<T> = T Function();

class CircularDependencyError extends Error {
  final Type type;
  CircularDependencyError(this.type);

  @override
  String toString() =>
      'CircularDependencyError: circular dep detected for $type';
}

abstract class Disposable {
  void dispose();
}

class _Registration<T> {
  final FactoryFunc<T> factoryFunc;
  final Scope scope;
  _Registration(this.factoryFunc, this.scope);
}

class _ScopedContainer {
  final Map<_RegistrationKey, Object> _instances = {};

  T? get<T>(String? name) {
    final key = _RegistrationKey(T, name);
    return _instances[key] as T?;
  }

  void set<T>(String? name, T instance) {
    _instances[_RegistrationKey(T, name)] = instance as Object;
  }

  void dispose() {
    for (final instance in _instances.values) {
      if (instance is Disposable) {
        instance.dispose();
      }
    }
    _instances.clear();
  }
}

class _RegistrationKey {
  final Type type;
  final String? name;
  const _RegistrationKey(this.type, this.name);

  @override
  bool operator ==(Object other) =>
      other is _RegistrationKey && other.type == type && other.name == name;

  @override
  int get hashCode => Object.hash(type, name);
}

class CubePod {
  static final CubePod _instance = CubePod._();
  CubePod._();

  static CubePod get instance => _instance;

  final Map<_RegistrationKey, _Registration> _registrations = {};
  final Map<_RegistrationKey, Object> _singletons = {};
  final Set<Type> _resolving = {}; // Cycle detection
  _ScopedContainer? _currentScope;

  static void register<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    Scope scope = Scope.factory,
    String? name,
  }) {
    final key = _RegistrationKey(T, name);
    _instance._registrations[key] = _Registration<T>(factoryFunc, scope);
    CubeDevToolsObserver.instance?.onDependencyRegistered(T, null);
  }

  static T get<T extends Object>({String? name}) {
    return _instance._resolve<T>(name: name);
  }

  static void unregister<T extends Object>({String? name}) {
    final key = _RegistrationKey(T, name);
    _instance._registrations.remove(key);
    final instance = _instance._singletons.remove(key);
    _instance._disposeIfNeeded(instance);
  }

  static void reset() {
    for (final instance in _instance._singletons.values) {
      _instance._disposeIfNeeded(instance);
    }
    _instance._registrations.clear();
    _instance._singletons.clear();
    _instance._resolving.clear();
  }

  static void pushScope() {
    _instance._currentScope = _ScopedContainer();
  }

  static void popScope() {
    _instance._currentScope?.dispose();
    _instance._currentScope = null;
  }

  T _resolve<T extends Object>({String? name}) {
    if (_resolving.contains(T)) {
      throw CircularDependencyError(T);
    }

    final key = _RegistrationKey(T, name);
    final registration = _registrations[key] as _Registration<T>?;
    if (registration == null) {
      throw StateError(
          'Nothing registered for $T${name != null ? " ($name)" : ""}. '
          'Did you call CubePod.register<$T>(...)?');
    }

    _resolving.add(T);
    try {
      T resolvedInstance;
      switch (registration.scope) {
        case Scope.singleton:
          if (!_singletons.containsKey(key)) {
            _singletons[key] = registration.factoryFunc();
          }
          resolvedInstance = _singletons[key] as T;
          break;
        case Scope.factory:
          resolvedInstance = registration.factoryFunc();
          break;
        case Scope.scoped:
          final scope = _currentScope;
          if (scope == null) {
            resolvedInstance = registration.factoryFunc();
          } else {
            final existing = scope.get<T>(name);
            if (existing != null) {
              resolvedInstance = existing;
            } else {
              resolvedInstance = registration.factoryFunc();
              scope.set<T>(name, resolvedInstance);
            }
          }
          break;
      }
      CubeDevToolsObserver.instance?.onDependencyResolved(T, resolvedInstance);
      return resolvedInstance;
    } finally {
      _resolving.remove(T);
    }
  }

  void _disposeIfNeeded(Object? instance) {
    if (instance is Disposable) {
      instance.dispose();
      CubeDevToolsObserver.instance
          ?.onDependencyDisposed(instance.runtimeType, instance);
    }
  }
}
