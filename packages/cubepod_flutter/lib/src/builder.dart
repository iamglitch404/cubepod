import 'package:flutter/widgets.dart';
import 'package:cubepod_state/cubepod_state.dart';

typedef WatchFunc = T Function<T>(Signal<T> signal);

/// A widget that automatically rebuilds when any [Signal] it reads changes.
///
/// [CubeBuilder] implements fine-grained, automatic dependency tracking.
/// During each build, every signal accessed via the [watch] function is
/// tracked. When any tracked signal changes, only this widget rebuilds —
/// not its parent or siblings.
///
/// Signals that are no longer accessed in a subsequent build are automatically
/// unsubscribed, preventing stale subscriptions.
///
/// ## Usage
///
/// ```dart
/// CubeBuilder(
///   builder: (context, watch) {
///     final count = watch(counter);         // tracked
///     final name = watch(userName);         // tracked
///     return Text('$name: $count');
///   },
/// )
/// ```
///
/// See also:
/// - [CubeListenableBuilder] — for [ChangeNotifier]-based dependencies resolved
///   from the DI container.
/// - [CubeSelector] — for selective rebuilds based on a slice of a [Signal].
class CubeBuilder extends StatefulWidget {
  /// The builder function. Call [watch] with each [Signal] you want to
  /// subscribe to. The widget rebuilds whenever any watched signal changes.
  final Widget Function(BuildContext context, WatchFunc watch) builder;

  const CubeBuilder({super.key, required this.builder});

  @override
  State<CubeBuilder> createState() => _CubeBuilderState();
}

class _CubeBuilderState extends State<CubeBuilder> {
  final Set<Signal<dynamic>> _currentDeps = {};
  final Set<Signal<dynamic>> _allDeps = {};
  bool _isDirty = false;
  bool _isBuilding = false;

  T _watch<T>(Signal<T> signal) {
    if (!_isBuilding) {
      throw StateError(
          'watch() can only be called synchronously during the builder callback.');
    }
    _currentDeps.add(signal);
    if (_allDeps.add(signal)) {
      signal.addListener(_onSignalChanged);
    }
    return signal.value;
  }

  void _onSignalChanged() {
    if (!_isDirty && mounted) {
      _isDirty = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDirty = false;
    _isBuilding = true;
    _currentDeps.clear();

    final Widget result;
    try {
      result = widget.builder(context, _watch);
    } finally {
      _isBuilding = false;
    }

    // Unsubscribe from signals that were NOT accessed in this build pass.
    final stale = _allDeps.difference(_currentDeps);
    for (final signal in stale) {
      signal.removeListener(_onSignalChanged);
      _allDeps.remove(signal);
    }

    return result;
  }

  @override
  void dispose() {
    for (final signal in _allDeps) {
      signal.removeListener(_onSignalChanged);
    }
    _allDeps.clear();
    _currentDeps.clear();
    super.dispose();
  }
}
