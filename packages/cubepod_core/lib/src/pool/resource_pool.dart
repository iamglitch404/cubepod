import 'package:cubepod_core/src/lifecycle/disposable.dart';

class ResourcePool<T extends Disposable> implements Disposable {
  final List<T> _available = [];
  final List<T> _inUse = [];
  final T Function() _factory;
  final int maxSize;
  bool _isDisposed = false;

  /// Creates a [ResourcePool] with a maximum capacity.
  ///
  /// Throws [ArgumentError] if [maxSize] is less than or equal to 0.
  ResourcePool(this._factory, {this.maxSize = 10}) {
    if (maxSize <= 0) {
      throw ArgumentError('maxSize must be greater than 0, but was $maxSize');
    }
  }

  /// Acquires a resource from the pool.
  ///
  /// Throws [StateError] if the pool is disposed or if it has reached [maxSize].
  T acquire() {
    if (_isDisposed) throw StateError('ResourcePool has been disposed');
    if (_available.isNotEmpty) {
      final r = _available.removeLast();
      _inUse.add(r);
      return r;
    }
    if (_inUse.length < maxSize) {
      final r = _factory();
      _inUse.add(r);
      return r;
    }
    throw StateError('Pool is full (max: $maxSize)');
  }

  /// Releases a resource back to the pool.
  ///
  /// Throws [StateError] if the pool is disposed.
  void release(T resource) {
    if (_isDisposed) throw StateError('ResourcePool has been disposed');
    if (_inUse.remove(resource)) {
      _available.add(resource);
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final r in [..._available, ..._inUse]) {
      r.dispose();
    }
    _available.clear();
    _inUse.clear();
  }
}
