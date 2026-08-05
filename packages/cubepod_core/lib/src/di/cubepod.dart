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
    return _instances[_RegistrationKey(T, name)] as T?;
  }

  void set<T>(String? name, T instance) {
    _instances[_RegistrationKey(T, name)] = instance as Object;
  }

  void dispose() {
    for (final instance in _instances.values) {
      if (instance is Disposable) instance.dispose();
    }
    _instances.clear();
  }
}

class _RegistrationKey {
  final Type type;
  final String? name;

  // Pre-compute hashCode once — it gets hit on every get<T>() call.
  @override
  final int hashCode;

  _RegistrationKey(this.type, this.name)
      : hashCode = name == null ? type.hashCode : Object.hash(type, name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _RegistrationKey && other.type == type && other.name == name);
}

class CubePod {
  static final CubePod _instance = CubePod._();
  CubePod._();

  static CubePod get instance => _instance;

  final Map<_RegistrationKey, _Registration> _registrations = {};

  // Singletons stored separately — singleton get<T>() is the hot path
  // and should not share a map with factories.
  final Map<_RegistrationKey, Object> _singletons = {};

  // Cycle detection is only relevant during the *initial* resolution of a
  // factory or singleton. Once a singleton is cached we never enter this set.
  final Set<Type> _resolving = {};

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
    final removed = _instance._singletons.remove(key);
    _instance._disposeIfNeeded(removed);
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
    final key = _RegistrationKey(T, name);

    // Fast path: singleton already cached — no cycle check, no map wrapping.
    final cached = _singletons[key];
    if (cached != null) return cached as T;

    final registration = _registrations[key] as _Registration<T>?;
    if (registration == null) {
      throw StateError(
        'Nothing registered for $T${name != null ? " ($name)" : ""}. '
        'Did you call CubePod.register<$T>(...)?',
      );
    }

    // Slow path: first-time resolution — guard against circular deps.
    if (_resolving.contains(T)) throw CircularDependencyError(T);
    _resolving.add(T);

    try {
      final T resolved;
      switch (registration.scope) {
        case Scope.singleton:
          final instance = registration.factoryFunc();
          _singletons[key] = instance;
          resolved = instance;
          break;
        case Scope.factory:
          resolved = registration.factoryFunc();
          break;
        case Scope.scoped:
          final scope = _currentScope;
          if (scope == null) {
            resolved = registration.factoryFunc();
          } else {
            final existing = scope.get<T>(name);
            if (existing != null) {
              resolved = existing;
            } else {
              final instance = registration.factoryFunc();
              scope.set<T>(name, instance);
              resolved = instance;
            }
          }
          break;
      }
      CubeDevToolsObserver.instance?.onDependencyResolved(T, resolved);
      return resolved;
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
