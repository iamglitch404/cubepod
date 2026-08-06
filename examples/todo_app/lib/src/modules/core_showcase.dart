import 'package:flutter/material.dart';
import 'package:cubepod_core/cubepod_core.dart';
import '../diagnostics/diagnostics_service.dart';

class _ScopedService implements Disposable {
  final int id;
  _ScopedService(this.id);
  @override
  void dispose() {
    debugPrint('Disposing _ScopedService $id');
  }
}

class CoreShowcasePage extends StatelessWidget {
  const CoreShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Core & DI Showcase')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () {
              try {
                CubePod.register<_ScopedService>(
                    (c) =>
                        _ScopedService(DateTime.now().millisecondsSinceEpoch),
                    scope: Scope.scoped);
              } catch (e) {
                // Expected duplicate registration caught
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text("Expected duplicate registration caught: $e")));
              }
            },
            child: const Text('Register Scoped Service (Expect Error)'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scope = CubePod.createScope();
              scope.register<_ScopedService>(
                  (c) => _ScopedService(DateTime.now().millisecondsSinceEpoch),
                  scope: Scope.scoped);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text("Temporary scope created and service registered.")));

              await Future.delayed(const Duration(seconds: 1));
              
              if (!context.mounted) return;

              scope.dispose();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      "Temporary scope disposed. Check DevTools for disposal event.")));
            },
            child: const Text('Lifecycle Test (Create & Dispose Scope)'),
          ),
          ElevatedButton(
            onPressed: () {
              CubePod.unregister<_ScopedService>();
            },
            child: const Text('Unregister Scoped Service'),
          ),
          const Divider(),
          ElevatedButton(
            onPressed: () {
              final dump = CubePod.debugDump();
              debugPrint(dump);
              // Also add to diagnostics logs
              CubePod.get<DiagnosticsService>()
                  .logInfo('Registry Dump:\n$dump');
            },
            child: const Text('Dump Registry to Console'),
          ),
        ],
      ),
    );
  }
}
