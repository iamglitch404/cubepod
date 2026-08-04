abstract class RetryPolicy {
  final int maxRetries;
  const RetryPolicy(this.maxRetries);

  Duration getDelay(int attempt);
  bool shouldRetry(dynamic error) => true;
}

class LinearRetryPolicy extends RetryPolicy {
  final Duration delay;

  const LinearRetryPolicy(
      {int maxRetries = 3, this.delay = const Duration(seconds: 1)})
      : super(maxRetries);

  @override
  Duration getDelay(int attempt) => delay;
}

class ExponentialRetryPolicy extends RetryPolicy {
  final Duration initialDelay;
  final double multiplier;

  const ExponentialRetryPolicy({
    int maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.multiplier = 2.0,
  }) : super(maxRetries);

  @override
  Duration getDelay(int attempt) {
    return initialDelay * (attempt == 0 ? 1 : (attempt * multiplier));
  }
}
