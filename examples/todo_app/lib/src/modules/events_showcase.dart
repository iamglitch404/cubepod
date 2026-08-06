import 'package:flutter/material.dart';
import 'package:cubepod_events/cubepod_events.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';

class MyActor extends Actor<String, int> {
  MyActor() : super(0);

  @override
  Future<int> receive(String message, int state) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return state + 1;
  }
}

class EventsShowcasePage extends StatefulWidget {
  const EventsShowcasePage({super.key});

  @override
  State<EventsShowcasePage> createState() => _EventsShowcasePageState();
}

class _EventsShowcasePageState extends State<EventsShowcasePage> {
  late final CubeEventBus bus;
  late final MyActor actor;
  final logs = StateSignal<List<String>>([]);

  @override
  void initState() {
    super.initState();
    bus = CubeEventBus();
    actor = MyActor();

    bus.on<String>((event) {
      logs.update((l) => [...l, 'Bus received: $event']);
    });
  }

  @override
  void dispose() {
    bus.dispose();
    actor.dispose();
    logs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events & Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => bus.emit('Hello World'),
            child: const Text('Fire String Event on Bus'),
          ),
          CubeBuilder(builder: (context, watch) {
            // Note: Actor state isn't naturally reactive since it's not a Signal,
            // but for showcase we trigger rebuild via other means or wrap it.
            return Text('Actor State: ${actor.state}');
          }),
          ElevatedButton(
            onPressed: () {
              actor.send('Increment');
              setState(() {});
            },
            child: const Text('Dispatch to Actor (Async Increment)'),
          ),
          ElevatedButton(
            onPressed: () {
              for (int i = 0; i < 5; i++) {
                actor.send('Flood $i');
              }
              setState(() {});
            },
            child: const Text('Flood Actor (5x)'),
          ),
          const Divider(),
          CubeBuilder(builder: (context, watch) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: watch(logs).map((l) => Text(l)).toList(),
            );
          }),
        ],
      ),
    );
  }
}
