import 'dart:convert';
import 'dart:async';
import 'package:cubepod_storage/cubepod_storage.dart';
import 'package:cubepod_async/cubepod_async.dart';

abstract class SyncTask {
  String get id;
  String get type;
  Map<String, dynamic> toJson();
  Future<void> execute();
}

typedef TaskFactory = SyncTask Function(Map<String, dynamic> json);

enum SyncTaskStatus { pending, processing, failed }

class SyncQueueEvent {
  final String taskId;
  final SyncTaskStatus status;
  final Object? error;

  const SyncQueueEvent({
    required this.taskId,
    required this.status,
    this.error,
  });
}

class SyncQueue {
  final StorageService storage;
  final String storageKey;
  final RetryPolicy retryPolicy;
  final void Function(SyncQueueEvent)? onEvent;

  final Map<String, TaskFactory> _factories = {};
  final List<SyncTask> _tasks = [];
  final List<SyncTask> _deadLetterQueue = [];
  bool _isProcessing = false;

  SyncQueue({
    required this.storage,
    this.storageKey = 'cubepod_sync_queue',
    this.retryPolicy = const ExponentialRetryPolicy(maxRetries: 5),
    this.onEvent,
  });

  List<SyncTask> get pendingTasks => List.unmodifiable(_tasks);
  List<SyncTask> get failedTasks => List.unmodifiable(_deadLetterQueue);

  void registerFactory(String taskType, TaskFactory factory) {
    _factories[taskType] = factory;
  }

  Future<void> hydrate() async {
    final storedData = storage.getString(storageKey);
    if (storedData != null) {
      final List<dynamic> decoded = jsonDecode(storedData);
      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        final type = map['__type'] as String?;
        if (type != null) {
          final factory = _factories[type];
          if (factory != null) {
            _tasks.add(factory(map));
          }
        }
      }
    }
    if (_tasks.isNotEmpty) {
      _processQueue();
    }
  }

  void enqueue(SyncTask task) {
    _tasks.add(task);
    _persist();
    _processQueue();
  }

  void retryFailed() {
    _tasks.addAll(_deadLetterQueue);
    _deadLetterQueue.clear();
    _persist();
    _processQueue();
  }

  void _persist() {
    final list = _tasks.map((t) {
      final json = t.toJson();
      json['__type'] = t.type;
      return json;
    }).toList();
    storage.setString(storageKey, jsonEncode(list));
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_tasks.isNotEmpty) {
      final task = _tasks.first;
      onEvent?.call(
          SyncQueueEvent(taskId: task.id, status: SyncTaskStatus.processing));

      int attempt = 0;
      bool success = false;
      Object? lastError;

      while (attempt <= retryPolicy.maxRetries) {
        try {
          await task.execute();
          success = true;
          break;
        } catch (e) {
          lastError = e;
          attempt++;
          if (attempt <= retryPolicy.maxRetries) {
            await Future.delayed(retryPolicy.getDelay(attempt));
          }
        }
      }

      _tasks.removeAt(0);

      if (!success) {
        // Move to dead-letter queue instead of silently dropping
        _deadLetterQueue.add(task);
        onEvent?.call(SyncQueueEvent(
          taskId: task.id,
          status: SyncTaskStatus.failed,
          error: lastError,
        ));
      }
      _persist();
    }

    _isProcessing = false;
  }
}
