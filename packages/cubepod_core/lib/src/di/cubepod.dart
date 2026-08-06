import 'scope.dart';
import '../observability/observer.dart';
import '../lifecycle/disposable.dart';
part 'container.dart';

/// The global entry point for the CubePod dependency injection system.
///
/// [CubePod] manages a root [CubeContainer] and provides static helpers for
/// registering, resolving, and unregistering dependencies at the application
/// level. For scoped dependencies (e.g., per-screen), use [createScope] to
/// create a child container.
///
/// ## Quick Start
///
/// ```dart
/// void main() {
///   CubePod.register<ApiService>((c) => ApiService(), scope: Scope.singleton);
///   CubePod.register<UserRepo>((c) => UserRepo(c.get<ApiService>()));
///   runApp(MyApp());
/// }
/// ```
class CubePod {
  static final Set<_RegistrationKey> _resolving = {};

  /// The application-level root container. All registrations without an
  /// explicit scope target this container.
  static CubeContainer root = CubeContainer(name: 'root');

  /// Registers a factory function for type [T] in the root container.
  ///
  /// See [CubeContainer.register] for full documentation.
  static void register<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    Scope scope = Scope.factory,
    String? name,
    void Function(T instance)? onDispose,
  }) {
    root.register<T>(factoryFunc,
        scope: scope, name: name, onDispose: onDispose);
  }

  /// Resolves an instance of type [T] from the root container.
  ///
  /// See [CubeContainer.get] for full documentation.
  static T get<T extends Object>({String? name}) {
    return root.get<T>(name: name);
  }

  /// Creates a new child [CubeContainer] scoped under [parent] (defaults to [root]).
  ///
  /// The child inherits all registrations from its parent chain, but can
  /// override any of them locally. Scoped instances created in the child
  /// are disposed when [CubeContainer.dispose] is called on the child.
  ///
  /// ```dart
  /// final screen = CubePod.createScope();
  /// screen.register<HomeViewModel>((c) => HomeViewModel(c.get<UserRepo>()),
  ///     scope: Scope.scoped);
  /// ```
  static CubeContainer createScope({CubeContainer? parent, String? name}) {
    return CubeContainer(parent: parent ?? root, name: name);
  }

  /// Removes the registration for type [T] from the root container and
  /// disposes the instance.
  static void unregister<T extends Object>({String? name}) {
    root.unregister<T>(name: name);
  }

  /// Prints a formatted tree of all registrations and active instances
  /// in the root container to the console for debugging.
  static String debugDump() {
    return root.debugDump();
  }

  /// Disposes and clears all root registrations.
  ///
  /// Primarily used in tests to reset state between test cases.
  /// Also clears the circular-dependency detection stack.
  static void reset() {
    root.dispose();
    root = CubeContainer(name: 'root');
    _resolving.clear();
  }
}
