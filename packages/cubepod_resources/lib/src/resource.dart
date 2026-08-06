import 'dart:async';

/// An abstraction over acquiring and disposing asynchronous external resources.
abstract class Resource<T> {
  T? _instance;
  Future<T>? _initFuture;
  bool _isDisposed = false;

  Future<T> acquire() async {
    if (_isDisposed) throw StateError('Resource disposed');
    if (_instance != null) return _instance as T;

    _initFuture ??= create().then((val) {
      _instance = val;
      return val;
    });
    return _initFuture!;
  }

  Future<T> create();

  Future<void> release() async {
    if (_instance != null) {
      await dispose(_instance as T);
      _instance = null;
    }
    _initFuture = null;
    _isDisposed = true;
  }

  Future<void> dispose(T instance);
}
