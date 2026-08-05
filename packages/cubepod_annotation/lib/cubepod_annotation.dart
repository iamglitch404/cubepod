/// The lifecycle of a registered dependency.
enum CubeScope {
  /// One instance for the entire app lifetime.
  singleton,

  /// A fresh instance every time it is requested.
  factory,

  /// One instance per active scope (e.g. per route).
  scoped,
}

/// Marks a class as auto-injectable by `cubepod_generator`.
///
/// The generator scans for this annotation and wires up all dependencies
/// automatically, in the correct order, at build time.
///
/// ```dart
/// @CubeInjectable()
/// class UserRepo {
///   final ApiClient api;
///   UserRepo(this.api);
/// }
/// ```
class CubeInjectable {
  final CubeScope scope;

  /// Optional name for named registrations (e.g. multiple implementations).
  final String? name;

  const CubeInjectable({
    this.scope = CubeScope.singleton,
    this.name,
  });
}

// Shorthand annotations for common scopes.
const singleton = CubeInjectable(scope: CubeScope.singleton);
const factory = CubeInjectable(scope: CubeScope.factory);
const scoped = CubeInjectable(scope: CubeScope.scoped);

/// Marks the setup function where the generated `$initCubePod()` is called.
///
/// Place this on the function in your `di.dart` file:
/// ```dart
/// @cubepodInit
/// void setup() => $initCubePod();
/// ```
class CubePodInit {
  const CubePodInit();
}

const cubepodInit = CubePodInit();
