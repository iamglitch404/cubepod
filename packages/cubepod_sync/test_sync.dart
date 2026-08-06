import 'package:cubepod_sync/cubepod_sync.dart';
import 'package:cubepod_storage/cubepod_storage.dart';
import "package:cubepod_async/cubepod_async.dart" as cubepod_async;

class TestTask implements SyncTask {
  @override
  final String id;
  @override
  final String type = 'TestTask';

  TestTask(this.id);

  @override
  Map<String, dynamic> toJson() => {'id': id};

  @override
  Future<void> execute() async {
    throw Exception('Failed task');
  }
}

void main() async {
  final storage = MemoryStorage();
  await storage.init();

  final queue = SyncQueue(
    storage: storage,
    retryPolicy: const cubepod_async.LinearRetryPolicy(
        maxRetries: 0,
        delay: Duration(milliseconds: 0)), // no retries for speed
  );
  queue.registerFactory('TestTask', (json) => TestTask(json['id']));

  // Enqueue a task that will fail
  queue.enqueue(TestTask('123'));

  // Wait for processing to fail
  await Future.delayed(const Duration(milliseconds: 100));

  // Verify it is in dead letter queue
  print("Failed tasks length: ${queue.failedTasks.length}"); // Should be 1

  // Now simulate app restart
  final newQueue = SyncQueue(storage: storage);
  newQueue.registerFactory('TestTask', (json) => TestTask(json['id']));
  await newQueue.hydrate();

  print("New queue failed tasks length: ${newQueue.failedTasks.length}");
  if (newQueue.failedTasks.isEmpty) {
    throw Exception(
        "Bug reproduced! Failed tasks were not persisted and are lost upon restart.");
  }
}
