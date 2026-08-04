import 'package:flutter/widgets.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'listener.dart';
import 'builder.dart';

class CubeConsumer<T> extends StatelessWidget {
  final Signal<T> signal;
  final void Function(BuildContext context, T previous, T next) listener;
  final Widget Function(
      BuildContext context, S Function<S>(Signal<S> signal) watch) builder;

  const CubeConsumer({
    super.key,
    required this.signal,
    required this.listener,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return CubeListener<T>(
      signal: signal,
      listener: listener,
      child: CubeBuilder(builder: builder),
    );
  }
}
