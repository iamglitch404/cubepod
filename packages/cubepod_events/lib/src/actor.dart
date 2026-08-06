import 'dart:async';

abstract class Actor<Message, State> {
  State _state;
  State get state => _state;

  final _mailbox = StreamController<Message>();
  bool _isDisposed = false;

  Actor(this._state) {
    _run();
  }

  void send(Message msg) {
    if (_isDisposed) return;
    _mailbox.add(msg);
  }

  Future<void> _run() async {
    await for (final msg in _mailbox.stream) {
      if (_isDisposed) break;
      _state = await receive(msg, _state);
    }
  }

  Future<State> receive(Message msg, State state);

  void dispose() {
    _isDisposed = true;
    _mailbox.close();
  }
}
