class CancellationToken {
  bool _isCancelled = false;
  String? _reason;

  bool get isCancelled => _isCancelled;
  String? get reason => _reason;

  void cancel([String? reason]) {
    _isCancelled = true;
    _reason = reason;
  }

  void throwIfCancelled() {
    if (_isCancelled) throw CancelledException(_reason);
  }
}

class CancelledException implements Exception {
  final String? reason;
  CancelledException([this.reason]);

  @override
  String toString() => 'Cancelled${reason != null ? ': $reason' : ''}';
}
