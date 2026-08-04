import 'package:flutter/widgets.dart';
import 'package:cubepod_state/cubepod_state.dart';

typedef WatchFunc = T Function<T>(Signal<T> signal);

class CubeBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, WatchFunc watch) builder;

  const CubeBuilder({super.key, required this.builder});

  @override
  State<CubeBuilder> createState() => _CubeBuilderState();
}

class _CubeBuilderState extends State<CubeBuilder> {
  final Set<Signal<dynamic>> _currentDeps = {};

  final Set<Signal<dynamic>> _allDeps = {};
  bool _isDirty = false;

  T _watch<T>(Signal<T> signal) {
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
    // Track which signals are accessed this build
    _currentDeps.clear();

    final result = widget.builder(context, _watch);

    // Unsubscribe from signals that were NOT accessed in this build pass
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
