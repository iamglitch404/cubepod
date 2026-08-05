import 'package:cubepod_state/cubepod_state.dart';
import 'retry_policy.dart';
import 'cancellation_token.dart';

enum AsyncStatus { initial, loading, success, error }

class AsyncState<T> {
  final AsyncStatus status;
  final T? data;
  final Object? error;

  const AsyncState({
    this.status = AsyncStatus.initial,
    this.data,
    this.error,
  });

  const AsyncState.loading([this.data])
      : status = AsyncStatus.loading,
        error = null;
  const AsyncState.success(this.data)
      : status = AsyncStatus.success,
        error = null;
  const AsyncState.error(this.error, [this.data]) : status = AsyncStatus.error;

  bool get isLoading => status == AsyncStatus.loading;
  bool get hasData => status == AsyncStatus.success;
  bool get hasError => status == AsyncStatus.error;
}

class AsyncSignal<T> extends StateSignal<AsyncState<T>> {
  AsyncSignal([T? initialData]) : super(AsyncState<T>(data: initialData));

  /// Resets the signal back to its initial idle state, clearing data and error.
  void reset() {
    value = const AsyncState();
  }

  Future<void> execute(
    Future<T> Function(CancellationToken token) task, {
    RetryPolicy? retryPolicy,
    CancellationToken? token,
  }) async {
    value = AsyncState.loading(value.data);
    final currentToken = token ?? CancellationToken();

    int attempt = 0;
    while (true) {
      try {
        currentToken.throwIfCancelled();
        final result = await task(currentToken);
        currentToken.throwIfCancelled();
        value = AsyncState.success(result);
        return;
      } catch (e) {
        if (e is CancelledException) {
          value = AsyncState.error(e, value.data);
          return;
        }

        if (retryPolicy != null &&
            attempt < retryPolicy.maxRetries &&
            retryPolicy.shouldRetry(e)) {
          attempt++;
          await Future.delayed(retryPolicy.getDelay(attempt));
          continue;
        }

        value = AsyncState.error(e, value.data);
        return;
      }
    }
  }
}
