import 'dart:async';
import 'package:cubepod_async/cubepod_async.dart';

class AsyncStreamSignal<T> extends AsyncSignal<T> {
  StreamSubscription<T>? _subscription;

  AsyncStreamSignal({
    required Stream<T> stream,
    T? initialData,
  }) : super(initialData) {
    value = AsyncState.loading(initialData);
    _subscription = stream.listen(
      (data) => value = AsyncState.success(data),
      onError: (Object e) => value = AsyncState.error(e, value.data),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
