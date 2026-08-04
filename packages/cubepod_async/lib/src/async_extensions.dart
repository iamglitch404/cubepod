import 'async_signal.dart';

extension AsyncSignalExtensions<T> on AsyncSignal<T> {
  void reset() {
    value = AsyncState<T>();
  }
}
