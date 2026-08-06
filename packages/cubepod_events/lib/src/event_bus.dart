import 'dart:async';

/// A lightweight, application-wide event bus for decoupled communication.
///
/// Uses a broadcast `StreamController` under the hood. Any part of the
/// application can emit events, and any part can listen for specific types.
///
/// ```dart
/// // Listen for events
/// CubeEventBus().on<UserLoggedIn>((event) => print(event.userId));
///
/// // Emit events
/// CubeEventBus().emit(UserLoggedIn('123'));
/// ```
class CubeEventBus {
  static CubeEventBus? _instance;

  /// Returns the global singleton instance of the event bus.
  factory CubeEventBus() => _instance ??= CubeEventBus._internal();

  CubeEventBus._internal();

  final _controller = StreamController<dynamic>.broadcast();
  bool _isDisposed = false;

  /// Emits an event to all registered listeners.
  ///
  /// If the bus has been disposed, this operation is a safe no-op.
  void emit(dynamic event) {
    if (_isDisposed) {
      // ignore: avoid_print
      print('[CubeEventBus] Warning: emit() called after dispose()');
      return;
    }
    _controller.add(event);
  }

  /// Listens for events of type [T].
  ///
  /// Returns a [StreamSubscription] that must be cancelled when no longer needed
  /// to prevent memory leaks.
  StreamSubscription<T> on<T>(void Function(T event) handler) {
    if (_isDisposed) {
      // Return a dummy empty stream subscription if disposed.
      return Stream<T>.empty().listen(handler);
    }
    return _controller.stream.where((e) => e is T).cast<T>().listen(handler);
  }

  /// Closes the event bus and cleans up the global instance.
  ///
  /// Subsequent calls to the [CubeEventBus] factory will create a fresh instance.
  void dispose() {
    _isDisposed = true;
    _controller.close();
    if (identical(this, _instance)) {
      _instance = null;
    }
  }
}

/// Emits an event to the global [CubeEventBus].
void emitEvent(dynamic event) => CubeEventBus().emit(event);

/// Listens for events of type [T] on the global [CubeEventBus].
StreamSubscription<T> onEvent<T>(void Function(T event) handler) =>
    CubeEventBus().on<T>(handler);
