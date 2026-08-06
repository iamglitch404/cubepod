/// A token that can be passed to asynchronous operations to signal cancellation.
class CancellationToken {
  bool _isCancelled = false;
  String? _reason;

  /// Whether this token has been cancelled.
  bool get isCancelled => _isCancelled;
  String? get reason => _reason;

  /// Cancels this token, optionally providing a [reason].
  void cancel([String? reason]) {
    _isCancelled = true;
    _reason = reason;
  }

  /// Throws a [CancelledException] if this token has been cancelled.
  void throwIfCancelled() {
    if (_isCancelled) throw CancelledException(_reason);
  }
}

/// An exception thrown when an operation is cancelled via [CancellationToken].
class CancelledException implements Exception {
  final String? reason;
  CancelledException([this.reason]);

  @override
  String toString() => 'Cancelled${reason != null ? ': $reason' : ''}';
}
