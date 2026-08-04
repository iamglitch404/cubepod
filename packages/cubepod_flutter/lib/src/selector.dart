import 'package:flutter/widgets.dart';
import 'package:cubepod_state/cubepod_state.dart';

class CubeSelector<T, R> extends StatefulWidget {
  final Signal<T> signal;
  final R Function(T value) selector;
  final Widget Function(BuildContext context, R selected) builder;
  final bool Function(R previous, R next)? equals;

  const CubeSelector({
    super.key,
    required this.signal,
    required this.selector,
    required this.builder,
    this.equals,
  });

  @override
  State<CubeSelector<T, R>> createState() => _CubeSelectorState<T, R>();
}

class _CubeSelectorState<T, R> extends State<CubeSelector<T, R>> {
  late R _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selector(widget.signal.value);
    widget.signal.addListener(_onChanged);
  }

  void _onChanged() {
    final next = widget.selector(widget.signal.value);
    final isEqual = widget.equals != null
        ? widget.equals!(_selectedValue, next)
        : _selectedValue == next;

    if (!isEqual && mounted) {
      setState(() {
        _selectedValue = next;
      });
    }
  }

  @override
  void didUpdateWidget(CubeSelector<T, R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signal != widget.signal) {
      oldWidget.signal.removeListener(_onChanged);
      _selectedValue = widget.selector(widget.signal.value);
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
    return widget.builder(context, _selectedValue);
  }
}
