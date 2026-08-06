import 'package:flutter/widgets.dart';
import 'package:cubepod_core/cubepod_core.dart';

/// Provides a [CubeContainer] to its widget subtree.
///
/// [CubeScope] creates a new child [CubeContainer] scoped under the nearest
/// ancestor container (or [CubePod.root] if there is none). It exposes the
/// container to all descendants via [CubeScope.of] and [context.get<T>()].
///
/// ## Basic Usage
///
/// ```dart
/// CubeScope(
///   overrides: (c) {
///     c.register<HomeViewModel>(
///       (c) => HomeViewModel(c.get<UserRepo>()),
///       scope: Scope.scoped,
///     );
///   },
///   child: HomeScreen(),
/// )
/// ```
///
/// ## Lifecycle
///
/// The container is created in [State.didChangeDependencies] and disposed
/// automatically when the [CubeScope] widget is removed from the tree.
/// All [Disposable] instances registered in the scope are disposed with it.
class CubeScope extends StatefulWidget {
  final Widget child;

  /// An optional debug name for this scope, visible in DevTools.
  final String? name;

  /// An optional callback to register or override dependencies in the new
  /// child container before it is exposed to the subtree.
  ///
  /// **Warning:** This closure is executed exactly once during widget
  /// initialization. If the parent widget rebuilds and passes a new closure
  /// (or captures new state), it will be ignored. Use this exclusively for
  /// static dependency initialization.
  final void Function(CubeContainer)? overrides;

  const CubeScope({
    super.key,
    required this.child,
    this.name,
    this.overrides,
  });

  /// Returns the nearest [CubeContainer] in the widget tree, or `null`
  /// if no [CubeScope] ancestor exists.
  static CubeContainer? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CubeScopeInherited>();
    return scope?.container;
  }

  /// Returns the nearest [CubeContainer] in the widget tree.
  ///
  /// Throws [StateError] if no [CubeScope] ancestor exists. Prefer
  /// [maybeOf] when a scope is not guaranteed.
  static CubeContainer of(BuildContext context) {
    final container = maybeOf(context);
    if (container == null) {
      throw StateError(
          'CubeScope.of() called with a context that does not contain a CubeScope. '
          'Ensure a CubeScope widget wraps the calling widget.');
    }
    return container;
  }

  /// Wraps [child] in the current scope's [CubeScopeInherited] without
  /// creating a new container. Useful for preserving scope across navigation
  /// or overlay boundaries.
  static Widget capture(BuildContext context, Widget child) {
    final container = maybeOf(context) ?? CubePod.root;
    return CubeScopeInherited(
      container: container,
      child: child,
    );
  }

  /// Exposes an existing [container] to [child] without creating a new scope.
  ///
  /// Use this when you have already created a [CubeContainer] manually and
  /// want to inject it into the widget tree without going through [CubeScope]'s
  /// lifecycle management.
  static Widget runAsAmbient(CubeContainer container, Widget child) {
    return CubeScopeInherited(
      container: container,
      child: child,
    );
  }

  @override
  State<CubeScope> createState() => _CubeScopeState();
}

class _CubeScopeState extends State<CubeScope> {
  CubeContainer? container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (container == null) {
      final parentContainer = CubeScope.maybeOf(context);
      container = CubePod.createScope(
        parent: parentContainer,
        name: widget.name,
      );
      widget.overrides?.call(container!);
    }
  }

  @override
  void dispose() {
    container?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (container == null) return const SizedBox.shrink();
    return CubeScopeInherited(
      container: container!,
      child: widget.child,
    );
  }
}

/// Internal [InheritedWidget] that carries the [CubeContainer] reference
/// through the widget tree. Consumers use [CubeScope.of] or [context.get<T>()]
/// rather than interacting with this class directly.
class CubeScopeInherited extends InheritedWidget {
  final CubeContainer container;

  const CubeScopeInherited({
    super.key,
    required this.container,
    required super.child,
  });

  @override
  bool updateShouldNotify(CubeScopeInherited oldWidget) {
    return container != oldWidget.container;
  }
}
