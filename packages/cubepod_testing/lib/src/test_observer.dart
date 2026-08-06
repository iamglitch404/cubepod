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

  /// Asserts that the history of values emitted exactly matches the provided iterable.
  void assertValues(Iterable<T> values) {
    final expected = values.toList();
    if (history.length != expected.length) {
      throw StateError(
          'TestObserver: Expected ${expected.length} values, but got ${history.length}.\n'
          'Expected: $expected\n'
          'Actual: $history');
    }
    for (int i = 0; i < expected.length; i++) {
      if (history[i] != expected[i]) {
        throw StateError('TestObserver: Value mismatch at index $i.\n'
            'Expected: ${expected[i]}\n'
            'Actual: ${history[i]}');
      }
    }
  }

  /// Asserts that the most recent value emitted matches the provided value.
  void assertLast(T value) {
    if (history.isEmpty) {
      throw StateError('TestObserver: No values have been emitted.');
    }
    if (history.last != value) {
      throw StateError(
          'TestObserver: Expected last value to be $value, but got ${history.last}.');
    }
  }
}
