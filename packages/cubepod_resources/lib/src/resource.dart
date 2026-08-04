import 'dart:async';

abstract class Resource<T> {
  T? _instance;
  bool _isDisposed = false;

  Future<T> acquire() async {
    if (_isDisposed) throw StateError('Resource disposed');
    if (_instance == null) {
      _instance = await create();
    }
    return _instance as T;
  }

  Future<T> create();

  Future<void> release() async {
    if (_instance != null) {
      await dispose(_instance!);
      _instance = null;
    }
    _isDisposed = true;
  }

  Future<void> dispose(T instance);
}
