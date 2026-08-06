import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_async/cubepod_async.dart';
import 'dart:async';

void main() async {
  final source = StateSignal<int>(0);
  final debounced = source.debounce(const Duration(milliseconds: 10));

  // This listener just makes sure we are observing the effect indirectly.
  // Wait, if debounced is disposed, we can't listen to it.
  // We can track if the internal timer keeps getting created.

  // Dispose the debounced signal
  debounced.dispose();

  // Now change the source signal.
  source.value = 1;
  source.value = 2;

  // Wait enough time for the debounce timer
  await Future.delayed(const Duration(milliseconds: 50));

  // The problem is that the effect is still alive, so it tried to update debounced.value
  // Wait, updating debounced.value after it's disposed might throw an error if StateSignal throws on setting value when disposed.
  // Does it throw? Let's see!
}
