import 'package:cubepod_core/src/di/cubepod.dart';

class ResourcePool<T extends Disposable> implements Disposable {
  final List<T> _available = [];
  final List<T> _inUse = [];
  final T Function() _factory;
  final int maxSize;

  ResourcePool(this._factory, {this.maxSize = 10});

  T acquire() {
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

  void release(T resource) {
    if (_inUse.remove(resource)) {
      _available.add(resource);
    }
  }

  @override
  void dispose() {
    for (final r in [..._available, ..._inUse]) {
      r.dispose();
    }
    _available.clear();
    _inUse.clear();
  }
}
