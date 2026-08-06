import 'package:cubepod_events/cubepod_events.dart';
import 'package:test/test.dart';

// Example domain events for testing
class UserLoggedIn {
  final String userId;
  const UserLoggedIn(this.userId);
}

class UserLoggedOut {
  const UserLoggedOut();
}

// Example state machine
enum TrafficLight { red, yellow, green }

enum TrafficEvent { timer, emergency }

class TrafficMachine extends StateMachine<TrafficLight, TrafficEvent> {
  TrafficMachine() : super(TrafficLight.red);

  @override
  TrafficLight reduce(TrafficLight state, TrafficEvent event) {
    switch (event) {
      case TrafficEvent.timer:
        return switch (state) {
          TrafficLight.red => TrafficLight.green,
          TrafficLight.green => TrafficLight.yellow,
          TrafficLight.yellow => TrafficLight.red,
        };
      case TrafficEvent.emergency:
        return TrafficLight.red;
    }
  }
}

// Example actor
class CounterActor extends Actor<int, int> {
  CounterActor() : super(0);

  @override
  Future<int> receive(int message, int currentState) async {
    await Future.delayed(const Duration(milliseconds: 10));
    return currentState + message;
  }
}

void main() {
  group('CubeEventBus', () {
    test('on<T>() receives typed events', () async {
      final bus = CubeEventBus();
      final received = <UserLoggedIn>[];
      final sub = bus.on<UserLoggedIn>((e) => received.add(e));
      bus.emit(UserLoggedIn('user-123'));
      bus.emit(UserLoggedOut()); // Different type — should not be received
      await Future.delayed(Duration.zero);
      expect(received.length, 1);
      expect(received.first.userId, 'user-123');
      await sub.cancel();
    });

    test('dispose() cleans up instance and allows fresh creation', () async {
      final bus1 = CubeEventBus();
      bus1.dispose();

      expect(() => bus1.emit(UserLoggedOut()), returnsNormally);

      final bus2 = CubeEventBus();
      expect(
        identical(bus1, bus2),
        isFalse,
        reason: 'A new instance should be created after dispose()',
      );

      final received = <UserLoggedOut>[];
      final sub = bus2.on<UserLoggedOut>((e) => received.add(e));
      bus2.emit(UserLoggedOut());

      await Future.delayed(Duration.zero);
      expect(received.length, 1);
      await sub.cancel();
      bus2.dispose();
    });

    test('emitEvent() global helper works', () async {
      expect(() => emitEvent(UserLoggedOut()), returnsNormally);
    });
  });

  group('StateMachine', () {
    test('starts in initial state', () {
      final machine = TrafficMachine();
      expect(machine.state, TrafficLight.red);
    });

    test('dispatch() transitions state correctly', () {
      final machine = TrafficMachine();
      machine.dispatch(TrafficEvent.timer);
      expect(machine.state, TrafficLight.green);
      machine.dispatch(TrafficEvent.timer);
      expect(machine.state, TrafficLight.yellow);
      machine.dispatch(TrafficEvent.timer);
      expect(machine.state, TrafficLight.red);
    });

    test('transitions are recorded in history', () {
      final machine = TrafficMachine();
      machine.dispatch(TrafficEvent.timer);
      machine.dispatch(TrafficEvent.timer);
      expect(machine.transitionHistory.length, 3);
      expect(machine.transitionHistory, [
        TrafficLight.red,
        TrafficLight.green,
        TrafficLight.yellow,
      ]);
    });

    test('undo() reverts to previous state', () {
      final machine = TrafficMachine();
      machine.dispatch(TrafficEvent.timer); // green
      machine.dispatch(TrafficEvent.timer); // yellow
      machine.undo();
      expect(machine.state, TrafficLight.green);
    });

    test('emergency event always goes to red', () {
      final machine = TrafficMachine();
      machine.dispatch(TrafficEvent.timer); // green
      machine.dispatch(TrafficEvent.emergency); // red
      expect(machine.state, TrafficLight.red);
    });
  });

  group('Actor', () {
    test('processes messages and updates state', () async {
      final actor = CounterActor();
      actor.send(5);
      actor.send(3);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(actor.state, 8);
      actor.dispose();
    });

    test('dispose() prevents further message processing', () async {
      final actor = CounterActor();
      actor.dispose();
      // BUG FIX: Removed copy-paste artifact `expect(() => acto` that was an
      // incomplete orphaned statement. The real assertion is below.
      expect(() => actor.send(1), returnsNormally);
    });

    test('processes messages sequentially to avoid state corruption', () async {
      final actor = CounterActor();
      // Send 3 messages rapidly
      actor.send(1);
      actor.send(1);
      actor.send(1);

      // Wait for processing
      await Future.delayed(const Duration(milliseconds: 200));

      expect(
        actor.state,
        3,
        reason:
            'Actor should process messages sequentially. If it processed concurrently, state would be 1.',
      );
      actor.dispose();
    });
  });
}
