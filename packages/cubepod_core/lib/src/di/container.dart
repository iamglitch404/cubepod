part of 'cubepod.dart';

/// The factory function signature used to register dependencies.
///
/// The [CubeContainer] passed in is the container currently performing the
/// resolution — use it to resolve transitive dependencies so that scoped
/// overrides are respected:
///
/// ```dart
/// CubePod.register<UserRepo>(
///   (c) => UserRepo(c.get<ApiService>()),
///   scope: Scope.singleton,
/// );
/// ```
typedef FactoryFunc<T> = T Function(CubeContainer container);

/// Thrown when a circular dependency is detected during resolution.
///
/// This typically means type A depends on type B which depends on type A.
/// Circular dependencies are always a design error and cannot be resolved.
class CircularDependencyError extends Error {
  final String message;
  CircularDependencyError(this.message);

  @override
  String toString() => 'CircularDependencyError: $message';
}

class _Registration<T> {
  final FactoryFunc<T> factoryFunc;
  final Scope scope;
  final void Function(T instance)? onDispose;
  _Registration(this.factoryFunc, this.scope, {this.onDispose});
}

class _RegistrationKey {
  final Type type;
  final String? name;

  @override
  final int hashCode;

  _RegistrationKey(this.type, this.name)
      : hashCode = name == null ? type.hashCode : Object.hash(type, name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _RegistrationKey && other.type == type && other.name == name);
}

/// A scoped dependency injection container.
///
/// Each [CubeContainer] has an optional [parent]. When resolving a dependency,
/// the container first checks its own registrations, then walks up the parent
/// chain until the root is reached.
///
/// Containers are typically created via [CubePod.createScope] and managed
/// automatically by [CubeScope] in Flutter apps. Direct use is also supported
/// for non-Flutter environments or advanced scenarios.
///
/// ```dart
/// final child = CubePod.createScope();
/// child.register<Logger>((c) => FileLogger(), scope: Scope.scoped);
/// final logger = child.get<Logger>(); // resolves from child
/// ```
class CubeContainer {
  /// The parent container, or `null` if this is the root.
  final CubeContainer? parent;

  /// An optional debug name shown in DevTools and error messages.
  final String? name;

  bool _isDisposed = false;

  final Map<_RegistrationKey, Object> _instances = {};
  final Map<_RegistrationKey, _Registration> _registrations = {};

  CubeContainer({this.parent, this.name});

  /// Registers a factory function for type [T] with the given [scope].
  ///
  /// - [Scope.singleton]: one instance shared across the entire root container.
  ///   **Note:** This scope is only valid when registering on the root container.
  ///   If you need a singleton-like lifetime for a child scope, use [Scope.scoped].
  /// - [Scope.scoped]: one instance per [CubeContainer]; disposed with the container.
  /// - [Scope.factory]: a new instance on every [get] call (default).
  ///
  /// Optionally supply a [name] to register multiple implementations of the
  /// same type (e.g., named loggers or themed configurations).
  ///
  /// Throws [ArgumentError] if [Scope.singleton] is used on a child container.
  void register<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    Scope scope = Scope.factory,
    String? name,
    void Function(T instance)? onDispose,
  }) {
    if (_isDisposed) throw StateError('CubeContainer has been disposed');
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('name cannot be empty or whitespace');
    }
    if (scope == Scope.singleton && parent != null) {
      throw ArgumentError(
          'Scope.singleton can only be registered on the root container. '
          'To scope an instance to a child container, use Scope.scoped instead.');
    }
    final key = _RegistrationKey(T, name);
    if (_registrations.containsKey(key)) {
      throw StateError(
          'Dependency "$T" with name "$name" is already registered in this container.');
    }
    _registrations[key] =
        _Registration<T>(factoryFunc, scope, onDispose: onDispose);
    CubeDevToolsObserver.instance?.onDependencyRegistered(T, null);
  }

  _Registration<T>? _getRegistration<T>(_RegistrationKey key) {
    if (_registrations.containsKey(key)) {
      return _registrations[key] as _Registration<T>;
    }
    return parent?._getRegistration<T>(key);
  }

  /// Resolves an instance of type [T] from this container.
  ///
  /// Resolution order:
  /// 1. Returns a cached instance if one exists for this scope.
  /// 2. Looks up the registration hierarchically (child → parent → root).
  /// 3. For [Scope.singleton], delegates to the parent until root is reached.
  /// 4. Instantiates and caches the instance for scoped/singleton lifetimes.
  ///
  /// Throws [StateError] if [T] is not registered.
  /// Throws [CircularDependencyError] if a circular dependency is detected.
  T get<T extends Object>({String? name}) {
    if (_isDisposed) throw StateError('CubeContainer has been disposed');
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('name cannot be empty or whitespace');
    }
    final key = _RegistrationKey(T, name);

    // 1. Fast path: check local instances
    if (_instances.containsKey(key)) {
      return _instances[key] as T;
    }

    // 2. Lookup registration hierarchically
    final registration = _getRegistration<T>(key);
    if (registration == null) {
      throw StateError(
          'Dependency "$T" not found in CubeContainer "${this.name ?? 'root'}". '
          'Did you forget to register it in this scope or a parent scope?');
    }

    // 3. Delegate Singletons to the parent container (until reaching root)
    if (registration.scope == Scope.singleton && parent != null) {
      return parent!.get<T>(name: name);
    }

    if (CubePod._resolving.contains(key)) {
      final path = CubePod._resolving
          .map((k) => k.name != null ? '${k.type}("${k.name}")' : '${k.type}')
          .join(' -> ');
      final target = name != null ? '$T("$name")' : '$T';
      throw CircularDependencyError(
          'Circular dependency detected: $path -> $target.');
    }
    CubePod._resolving.add(key);

    try {
      final T resolved;
      switch (registration.scope) {
        case Scope.singleton:
        case Scope.scoped:
          resolved = registration.factoryFunc(this);
          _instances[key] = resolved;
          break;
        case Scope.factory:
          resolved = registration.factoryFunc(this);
          break;
      }
      CubeDevToolsObserver.instance?.onDependencyResolved(T, resolved);
      return resolved;
    } finally {
      CubePod._resolving.remove(key);
    }
  }

  /// Directly sets an already-created instance for type [T].
  ///
  /// Useful for testing or for providing externally-managed singletons
  /// directly constructed by the container.
  void set<T extends Object>(T instance, {String? name}) {
    if (_isDisposed) throw StateError('CubeContainer has been disposed');
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('name cannot be empty or whitespace');
    }
    _instances[_RegistrationKey(T, name)] = instance;
  }

  /// Removes the registration for type [T] from this container and
  /// disposes the instance.
  void unregister<T extends Object>({String? name}) {
    if (_isDisposed) throw StateError('CubeContainer has been disposed');
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('name cannot be empty or whitespace');
    }
    final key = _RegistrationKey(T, name);
    final registration = _registrations.remove(key);
    final removed = _instances.remove(key);

    if (removed != null) {
      if (registration?.onDispose != null) {
        registration!.onDispose!(removed as T);
      } else if (removed is Disposable) {
        removed.dispose();
      }
      CubeDevToolsObserver.instance
          ?.onDependencyDisposed(removed.runtimeType, removed);
    }
  }

  /// Prints a formatted tree of all registrations and active instances
  /// in this container to the console for debugging.
  String debugDump() {
    final buffer = StringBuffer();
    buffer.writeln('CubeContainer: ${name ?? 'unnamed'}');
    buffer.writeln('  Registrations:');
    if (_registrations.isEmpty) {
      buffer.writeln('    (empty)');
    } else {
      for (final entry in _registrations.entries) {
        final key = entry.key;
        final reg = entry.value;
        final keyStr =
            key.name != null ? '${key.type}("${key.name}")' : '${key.type}';
        final isInstantiated = _instances.containsKey(key);
        final status = isInstantiated ? 'ACTIVE' : 'LAZY';
        buffer.writeln('    - $keyStr [${reg.scope.name}] ($status)');
      }
    }
    return buffer.toString();
  }

  /// Disposes this container and all [Disposable] instances it owns.
  ///
  /// Instances are disposed in reverse registration order (LIFO) so that
  /// dependencies are naturally torn down before the services that depend on them.
  ///
  /// After calling this method, the container can no longer be used, and
  /// all registrations and instances are cleared.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    final values = _instances.entries.toList().reversed;
    for (final entry in values) {
      final key = entry.key;
      final instance = entry.value;
      final registration = _registrations[key];

      if (registration?.onDispose != null) {
        registration!.onDispose!(instance);
        CubeDevToolsObserver.instance
            ?.onDependencyDisposed(instance.runtimeType, instance);
      } else if (instance is Disposable) {
        instance.dispose();
        CubeDevToolsObserver.instance
            ?.onDependencyDisposed(instance.runtimeType, instance);
      }
    }
    _instances.clear();
    _registrations.clear();
  }
}
