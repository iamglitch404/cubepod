import 'package:flutter/material.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';

class StateShowcasePage extends StatefulWidget {
  const StateShowcasePage({super.key});

  @override
  State<StateShowcasePage> createState() => _StateShowcasePageState();
}

class _StateShowcasePageState extends State<StateShowcasePage> {
  final count = StateSignal<int>(0, enableHistory: true);
  late final doubleCount = ComputedSignal<int>(() => count.value * 2);

  @override
  void dispose() {
    count.dispose();
    doubleCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('State Showcase')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CubeBuilder(builder: (context, watch) {
              return Text('Count: ${watch(count)}');
            }),
            CubeBuilder(builder: (context, watch) {
              return Text('Double: ${watch(doubleCount)}');
            }),
            ElevatedButton(
              onPressed: () => count.update((c) => c + 1),
              child: const Text('Increment'),
            ),
            ElevatedButton(
              onPressed: () => runTransaction(() {
                count.update((c) => c + 1);
                count.update((c) => c + 1);
              }),
              child: const Text('Transaction (+2)'),
            ),
            ElevatedButton(
              onPressed: () => count.undo(),
              child: const Text('Undo'),
            ),
            ElevatedButton(
              onPressed: () => count.redo(),
              child: const Text('Redo'),
            ),
          ],
        ),
      ),
    );
  }
}
