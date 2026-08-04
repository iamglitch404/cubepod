import 'package:flutter/widgets.dart';
import 'package:cubepod_state/cubepod_state.dart';

class CubeListener<T> extends StatefulWidget {
  final Signal<T> signal;
  final void Function(BuildContext context, T previous, T next) listener;
  final Widget child;

  const CubeListener({
    super.key,
    required this.signal,
    required this.listener,
    required this.child,
  });

  @override
  State<CubeListener<T>> createState() => _CubeListenerState<T>();
}

class _CubeListenerState<T> extends State<CubeListener<T>> {
  late T _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.signal.value;
    widget.signal.addListener(_onChanged);
  }

  void _onChanged() {
    final nextValue = widget.signal.value;
    widget.listener(context, _previousValue, nextValue);
    _previousValue = nextValue;
  }

  @override
  void didUpdateWidget(CubeListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signal != widget.signal) {
      oldWidget.signal.removeListener(_onChanged);
      _previousValue = widget.signal.value;
      widget.signal.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.signal.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
