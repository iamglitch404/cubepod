import 'dart:async';

class CubeEventBus {
  static final CubeEventBus _instance = CubeEventBus._internal();
  factory CubeEventBus() => _instance;
  CubeEventBus._internal();

  final _controller = StreamController<dynamic>.broadcast();
  bool _isDisposed = false;

  void emit(dynamic event) {
    if (_isDisposed) {
      // ignore: avoid_print
      print('[CubeEventBus] Warning: emit() called after dispose()');
      return;
    }
    _controller.add(event);
  }

  StreamSubscription<T> on<T>(void Function(T event) handler) {
    return _controller.stream.where((e) => e is T).cast<T>().listen(handler);
  }

  void dispose() {
    _isDisposed = true;
    _controller.close();
  }
}

// Global helpers following the Cube.emit / Cube.on pattern
void emitEvent(dynamic event) => CubeEventBus().emit(event);
StreamSubscription<T> onEvent<T>(void Function(T event) handler) =>
    CubeEventBus().on<T>(handler);
