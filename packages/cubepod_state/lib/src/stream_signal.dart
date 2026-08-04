import 'dart:async';
import 'package:cubepod_state/cubepod_state.dart';

class StreamSignal<T> extends StateSignal<T> {
  StreamSubscription<T>? _subscription;

  StreamSignal({
    required Stream<T> stream,
    required T initialValue,
    bool cancelOnError = false,
  }) : super(initialValue) {
    _subscription = stream.listen(
      (data) => value = data,
      onError: (Object e) {
        // Errors silently ignored — wrap with AsyncStreamSignal in cubepod_async
        // for full error state handling.
      },
      cancelOnError: cancelOnError,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
