import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_state/cubepod_state.dart';

class DiagnosticsService implements CubeObserver {
  final StateSignal<List<String>> _logs = StateSignal<List<String>>([]);
  final StateSignal<Map<Type, int>> _allocations =
      StateSignal<Map<Type, int>>({});

  StateSignal<List<String>> get logsSignal => _logs;
  StateSignal<Map<Type, int>> get allocationsSignal => _allocations;

  List<String> get logs => _logs.value;
  Map<Type, int> get allocations => _allocations.value;

  bool _isInternalUpdate = false;

  void logError(Object error, StackTrace stack) {
    _isInternalUpdate = true;
    _logs.update((l) {
      final updated = [...l, 'ERROR: $error'];
      return updated.length > 50
          ? updated.sublist(updated.length - 50)
          : updated;
    });
    _isInternalUpdate = false;
  }

  void logInfo(String message) {
    _isInternalUpdate = true;
    _logs.update((l) {
      final updated = [...l, 'INFO: $message'];
      return updated.length > 50
          ? updated.sublist(updated.length - 50)
          : updated;
    });
    _isInternalUpdate = false;
  }

  @override
  void onDependencyRegistered(Type type, dynamic instance) {
    logInfo('Registered $type');
  }

  @override
  void onDependencyResolved(Type type, dynamic instance) {
    _allocations.update((map) {
      final newMap = Map<Type, int>.from(map);
      newMap[type] = (newMap[type] ?? 0) + 1;
      return newMap;
    });
  }

  @override
  void onDependencyDisposed(Type type, dynamic instance) {
    _allocations.update((map) {
      final newMap = Map<Type, int>.from(map);
      final current = newMap[type] ?? 0;
      if (current > 1) {
        newMap[type] = current - 1;
      } else {
        newMap.remove(type);
      }
      return newMap;
    });
  }

  @override
  void onSignalCreated(String id, dynamic value) {
    if (_isInternalUpdate) return;
    logInfo('Signal created: $id');
  }

  @override
  void onSignalUpdated(String id, dynamic newValue, dynamic oldValue) {
    if (_isInternalUpdate) return;
    logInfo('Signal updated: $id');
  }
}
