import 'package:flutter/material.dart';
import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';
import 'package:cubepod_devtools/cubepod_devtools.dart';

// Signals
final counterSignal = StateSignal<int>(0, enableHistory: true);
final isEvenSignal = ComputedSignal(() => counterSignal.value % 2 == 0);

// Service
class LoggerService {
  void log(String message) => print('[CounterApp] $message');
}

void main() {
  CubePod.register(() => LoggerService(), scope: Scope.singleton);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StateInspector(
      child: MaterialApp(
        title: 'CubePod Counter',
        theme: ThemeData.dark(),
        home: const CounterPage(),
      ),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CubePod Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CubeBuilder(
              builder: (context, watch) {
                final count = watch(counterSignal);
                final isEven = watch(isEvenSignal);
                return Text(
                  'Count: $count\nIs Even: $isEven',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => counterSignal.undo(),
                  child: const Text('Undo'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => counterSignal.redo(),
                  child: const Text('Redo'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          counterSignal.update((v) => v + 1);
          context.get<LoggerService>().log(
            'Incremented to ${counterSignal.value}',
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
