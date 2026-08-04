import 'package:cubepod_state/cubepod_state.dart';

class TestObserver<T> {
  final Signal<T> signal;
  final List<T> history = [];

  TestObserver(this.signal) {
    history.add(signal.value);
    signal.addListener(_onChanged);
  }

  void _onChanged() {
    history.add(signal.value);
  }

  void dispose() {
    signal.removeListener(_onChanged);
  }
}
