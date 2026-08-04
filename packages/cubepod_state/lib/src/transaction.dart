import 'signal.dart';

class Transaction {
  static Transaction? _current;
  static Transaction? get current => _current;

  final Map<StateSignal, dynamic> _snapshots = {};
  bool _isRolledBack = false;

  void record(StateSignal signal, dynamic oldValue) {
    if (!_snapshots.containsKey(signal)) {
      _snapshots[signal] = oldValue;
    }
  }

  void rollback() {
    if (_isRolledBack) return;
    _isRolledBack = true;
    for (final entry in _snapshots.entries) {
      entry.key.setValueWithoutRecording(entry.value);
    }
  }
}

Future<void> runTransaction(Future<void> Function() action) async {
  if (Transaction._current != null) {
    return action();
  }

  final transaction = Transaction();
  Transaction._current = transaction;

  try {
    await action();
  } catch (e) {
    transaction.rollback();
    rethrow;
  } finally {
    Transaction._current = null;
  }
}
