import 'dart:math';

/// Defines a strategy for retrying failed asynchronous operations.
abstract class RetryPolicy {
  /// The maximum number of retry attempts before giving up.
  final int maxRetries;

  const RetryPolicy(this.maxRetries);

  /// Returns the duration to wait before the next attempt, given the current
  /// [attempt] number (1-indexed).
  Duration getDelay(int attempt);

  /// Determines whether the operation should be retried based on the thrown [error].
  ///
  /// By default, all errors are retried. Override this to prevent retries for
  /// fatal or non-transient errors.
  bool shouldRetry(dynamic error) => true;
}

/// A retry policy that waits for a fixed [delay] between attempts.
class LinearRetryPolicy extends RetryPolicy {
  /// The constant duration to wait between retries.
  final Duration delay;

  const LinearRetryPolicy({
    int maxRetries = 3,
    this.delay = const Duration(seconds: 1),
  }) : super(maxRetries);

  @override
  Duration getDelay(int attempt) => delay;
}

/// A retry policy that exponentially increases the delay between attempts.
class ExponentialRetryPolicy extends RetryPolicy {
  /// The initial delay duration for the first retry.
  final Duration initialDelay;

  /// The multiplier applied to the delay for each subsequent attempt.
  final double multiplier;

  /// Creates an exponential retry policy.
  ///
  /// Throws [ArgumentError] if [maxRetries] is less than 0, [initialDelay] is
  /// negative, or [multiplier] is less than 1.0.
  ExponentialRetryPolicy({
    int maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.multiplier = 2.0,
  }) : super(maxRetries) {
    if (maxRetries < 0) {
      throw ArgumentError.value(maxRetries, 'maxRetries', 'Cannot be negative');
    }
    if (initialDelay.isNegative) {
      throw ArgumentError.value(
          initialDelay, 'initialDelay', 'Cannot be negative');
    }
    if (multiplier < 1.0) {
      throw ArgumentError.value(multiplier, 'multiplier', 'Must be >= 1.0');
    }
  }

  @override
  Duration getDelay(int attempt) {
    // True exponential: initialDelay * multiplier^attempt
    // attempt=1 → initialDelay*2, attempt=2 → initialDelay*4, etc.
    final factor = pow(multiplier, attempt).toDouble();
    return initialDelay * factor;
  }
}
