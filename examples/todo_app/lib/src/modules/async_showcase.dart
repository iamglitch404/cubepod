import 'package:flutter/material.dart';
import 'package:cubepod_async/cubepod_async.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';

class AsyncShowcasePage extends StatefulWidget {
  const AsyncShowcasePage({super.key});

  @override
  State<AsyncShowcasePage> createState() => _AsyncShowcasePageState();
}

class _AsyncShowcasePageState extends State<AsyncShowcasePage> {
  final data = AsyncSignal<String>();
  CancellationToken? _token;

  @override
  void dispose() {
    _token?.cancel();
    data.dispose();
    super.dispose();
  }

  void _fetch() {
    _token?.cancel();
    _token = CancellationToken();
    data.execute((token) async {
      await Future.delayed(const Duration(seconds: 2));
      token.throwIfCancelled();
      return 'Loaded at ${DateTime.now()}';
    }, token: _token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Showcase')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CubeBuilder(builder: (context, watch) {
              final state = watch(data);
              if (state.isLoading) return const CircularProgressIndicator();
              if (state.hasError) return Text('Error: ${state.error}');
              if (state.hasData) return Text('Data: ${state.data}');
              return const Text('Initial');
            }),
            ElevatedButton(
              onPressed: _fetch,
              child: const Text('Fetch Data'),
            ),
            ElevatedButton(
              onPressed: () => _token?.cancel(),
              child: const Text('Cancel Fetch'),
            ),
          ],
        ),
      ),
    );
  }
}
