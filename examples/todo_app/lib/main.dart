import 'package:flutter/material.dart';
import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';
import 'package:cubepod_async/cubepod_async.dart';

// Async Signal
final todosSignal = AsyncSignal<List<String>>([]);

class TodoService {
  Future<List<String>> fetchTodos(CancellationToken token) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network
    return ['Buy milk', 'Learn CubePod', 'Ship app'];
  }
}

void main() {
  CubePod.register(() => TodoService(), scope: Scope.singleton);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TodoPage());
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    todosSignal.execute(
      (token) => context.get<TodoService>().fetchTodos(token),
      retryPolicy: const ExponentialRetryPolicy(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CubePod Async Todos')),
      body: CubeBuilder(
        builder: (context, watch) {
          final state = watch(todosSignal);

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasError) {
            return Center(child: Text('Error: ${state.error}'));
          }

          final todos = state.data ?? [];
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(todos[index]),
                leading: const Icon(Icons.check_circle_outline),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
