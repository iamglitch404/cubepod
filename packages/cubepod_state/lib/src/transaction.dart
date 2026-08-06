import 'dart:async';
import 'signal.dart';

class Transaction {
  static Transaction? get current =>
      Zone.current[#cubepod_transaction] as Transaction?;

  final Map<StateSignal, dynamic> _snapshots = {};
  final Set<VoidCallback> _deferredListeners = {};
  final Set<SignalObserver> _deferredObservers = {};
  bool _isRolledBack = false;
  bool isCommitting = false;

  void record(StateSignal signal, dynamic oldValue) {
    if (!_snapshots.containsKey(signal)) {
      _snapshots[signal] = oldValue;
    }
  }

  void deferListener(VoidCallback listener) {
    _deferredListeners.add(listener);
  }

  void deferObserver(SignalObserver observer) {
    _deferredObservers.add(observer);
  }

  void rollback() {
    if (_isRolledBack) return;
    _isRolledBack = true;
    for (final entry in _snapshots.entries) {
      entry.key.setValueWithoutRecording(entry.value);
    }
  }

  void commit() {
    if (_isRolledBack) return;
    isCommitting = true;
    for (final listener in _deferredListeners) {
      try {
        listener();
      } catch (e, stack) {
        SignalConfig.errorHandler(e, stack);
      }
    }
    for (final observer in _deferredObservers) {
      try {
        observer.onDependencyChanged();
      } catch (e, stack) {
        SignalConfig.errorHandler(e, stack);
      }
    }
  }
}

/// Executes [action] in a synchronous transaction.
///
/// Mutations to [StateSignal]s inside [action] are batched.
/// [ComputedSignal]s are invalidated immediately so reads inside the transaction
/// are accurate, but [Effect]s and UI rebuilds are deferred until the transaction completes.
///
/// If [action] throws an exception, all state mutations are rolled back.
///
/// Nested transactions are supported; only the outermost transaction batches
/// the updates.
void runTransaction(void Function() action) {
  if (Transaction.current != null) {
    return action();
  }

  final transaction = Transaction();

  try {
    runZoned(
      () => action(),
      zoneValues: {#cubepod_transaction: transaction},
    );
    transaction.commit();
  } catch (e) {
    transaction.rollback();
    rethrow;
  }
}
