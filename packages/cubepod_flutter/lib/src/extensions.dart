import 'package:flutter/widgets.dart';
import 'package:cubepod_core/cubepod_core.dart';
import 'scope.dart';

/// An extension on [BuildContext] that provides ergonomic access to the
/// nearest [CubeContainer] in the widget tree.
extension CubeContext on BuildContext {
  /// Resolves an instance of type [T] from the nearest [CubeScope].
  ///
  /// If no [CubeScope] is found in the widget tree, falls back to the
  /// application-level [CubePod.root] container.
  ///
  /// Optionally supply [name] to resolve a named registration.
  ///
  ///
  /// ```dart
  /// final api = context.get<ApiService>();
  /// final debugApi = context.get<ApiService>(name: 'debug');
  /// ```
  ///
  /// **Lifecycle Warning:** Do not call this method inside a [State.initState]
  /// method, as it relies on [InheritedWidget] resolution which requires the
  /// widget to be fully mounted. Use [State.didChangeDependencies] or [build]
  /// instead.
  ///
  /// Throws [StateError] if the type is not registered.
  T get<T extends Object>({String? name}) {
    final container = CubeScope.maybeOf(this);
    if (container != null) {
      return container.get<T>(name: name);
    }
    return CubePod.get<T>(name: name);
  }

  /// An alias for [get<T>] provided for developers migrating from `provider`
  /// or `flutter_riverpod`.
  ///
  /// Functions identically to [get<T>], fetching a dependency from the nearest
  /// [CubeScope] without listening to it.
  T read<T extends Object>({String? name}) => get<T>(name: name);
}
