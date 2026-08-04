abstract class StateMachine<S, E> {
  S _currentState;
  final List<S> transitionHistory = [];
  final int maxHistorySize;

  S get state => _currentState;

  StateMachine(this._currentState, {this.maxHistorySize = 50}) {
    transitionHistory.add(_currentState);
  }

  void dispatch(E event) {
    final nextState = reduce(_currentState, event);
    if (nextState != _currentState) {
      _currentState = nextState;
      transitionHistory.add(_currentState);
      if (transitionHistory.length > maxHistorySize) {
        transitionHistory.removeAt(0);
      }
      onTransition(_currentState, event);
    }
  }

  S reduce(S state, E event);

  void onTransition(S newState, E event) {}

  bool undo() {
    if (transitionHistory.length < 2) return false;
    transitionHistory.removeLast();
    _currentState = transitionHistory.last;
    return true;
  }
}
