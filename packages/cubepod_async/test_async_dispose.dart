import 'dart:async';
import 'package:test/test.dart';
import 'package:cubepod_async/cubepod_async.dart';

void main() {
  test('AsyncSignal disposed during execute does not crash unhandled',
      () async {
    final signal = AsyncSignal<String>();

    // Start execute but do not await it!
    final executeFuture = signal.execute((token) async {
      await Future.delayed(Duration(milliseconds: 50));
      return 'done';
    });

    // Dispose while it's running
    signal.dispose();

    // Wait for the task to finish. If it throws an unhandled exception, the test runner will fail.
    await Future.delayed(Duration(milliseconds: 100));

    // We should be able to await the execute future and expect it to complete normally or throw StateError predictably,
    // but not cause an unhandled async error.
    try {
      await executeFuture;
    } catch (e) {
      expect(e, isA<StateError>());
    }
  });
}
