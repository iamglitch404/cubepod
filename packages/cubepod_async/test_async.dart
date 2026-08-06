import 'package:cubepod_async/cubepod_async.dart';

void main() async {
  final signal = AsyncSignal<String>();

  // Start a slow request
  final slowTask = signal.execute((token) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 'stale_data';
  });

  // Immediately start a fast request that finishes BEFORE the slow request
  final fastTask = signal.execute((token) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return 'fresh_data';
  });

  // Wait for both to complete
  await Future.wait([fastTask, slowTask]);

  // The value should be 'fresh_data' because it was requested LAST.
  // If the slow task overwrote it when it finished, it will be 'stale_data'.
  print("Value: ${signal.value.data}");
  if (signal.value.data == 'stale_data') {
    throw Exception("Bug reproduced! Stale task overwrote fresh task.");
  }
}
