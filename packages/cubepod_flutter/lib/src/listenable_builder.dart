import 'package:flutter/widgets.dart';
import 'extensions.dart';

/// A widget that resolves a dependency [T] from the [CubeScope] and listens to it.
///
/// This provides a clean abstraction over `ListenableBuilder` and `context.get<T>()`.
/// It automatically resolves [T], which must extend [Listenable], from the closest
/// [CubeContainer] and rebuilds whenever the listenable notifies its listeners.
class CubeListenableBuilder<T extends Listenable> extends StatelessWidget {
  /// The builder function that is called every time the [T] instance updates.
  final Widget Function(BuildContext context, T instance, Widget? child)
      builder;

  /// An optional child widget which is passed to the [builder].
  /// Useful for optimizing rebuilds when a part of the subtree does not depend on [T].
  final Widget? child;

  const CubeListenableBuilder({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final instance = context.get<T>();
    return ListenableBuilder(
      listenable: instance,
      builder: (context, child) => builder(context, instance, child),
      child: child,
    );
  }
}
