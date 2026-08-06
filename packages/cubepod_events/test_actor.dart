import 'package:cubepod_events/cubepod_events.dart';
import 'dart:async';

class CounterActor extends Actor<int, int> {
  CounterActor() : super(0);

  @override
  Future<int> receive(int msg, int currentState) async {
    // Artificial delay to encourage overlapping
    await Future.delayed(const Duration(milliseconds: 50));
    return currentState + msg;
  }
}

void main() async {
  final actor = CounterActor();

  // Send 3 messages rapidly
  actor.send(1);
  actor.send(1);
  actor.send(1);

  await Future.delayed(const Duration(milliseconds: 200));

  print("Final state: ${actor.state}");
  if (actor.state != 3) {
    throw Exception("Actor state corruption! Expected 3, got ${actor.state}");
  }
}
