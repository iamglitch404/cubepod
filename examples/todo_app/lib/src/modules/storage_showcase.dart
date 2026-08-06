import 'package:flutter/material.dart';
import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_storage/cubepod_storage.dart';
import 'package:cubepod_sync/cubepod_sync.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';

class MySyncTask extends SyncTask {
  @override
  final String id;
  @override
  final String type = 'my_task';
  final Map<String, dynamic> payload;

  MySyncTask(this.id, this.payload);

  @override
  Map<String, dynamic> toJson() => {'id': id, 'payload': payload};

  @override
  Future<void> execute() async {
    await Future.delayed(const Duration(seconds: 1));
    if (payload['fail'] == true) throw Exception('Simulated failure');
  }
}

class StorageShowcasePage extends StatefulWidget {
  const StorageShowcasePage({super.key});

  @override
  State<StorageShowcasePage> createState() => _StorageShowcasePageState();
}

class _StorageShowcasePageState extends State<StorageShowcasePage> {
  late final StorageService storage;
  late final SyncQueue queue;
  late final PersistedSignal<int> counter;

  @override
  void initState() {
    super.initState();
    // Retrieve the globally initialized storage service from the DI container!
    storage = CubePod.get<StorageService>();
    queue = SyncQueue(
      storage: storage,
      storageKey: 'showcase_queue',
    );
    counter = PersistedSignal<int>(
      storage: storage,
      key: 'showcase_counter',
      initialValue: 0,
      deserialize: (s) => int.tryParse(s) ?? 0,
      serialize: (val) => val.toString(),
    );
    _init();
  }

  bool _isReady = false;

  Future<void> _init() async {
    // Storage is already init() in main.dart, we just need to hydrate our sync & state.
    await queue.hydrate();
    await counter.hydrate();
    if (mounted) setState(() => _isReady = true);
  }

  @override
  void dispose() {
    counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Storage & Sync Showcase')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CubeBuilder(builder: (context, watch) {
            return Text('Persisted Counter: ${watch(counter)}');
          }),
          ElevatedButton(
            onPressed: () => counter.update((c) => c + 1),
            child: const Text('Increment Persisted Counter'),
          ),
          const Divider(),
          ElevatedButton(
            onPressed: () => queue.enqueue(MySyncTask('1', {'fail': false})),
            child: const Text('Enqueue Success Task'),
          ),
          ElevatedButton(
            onPressed: () => queue.enqueue(MySyncTask('2', {'fail': true})),
            child: const Text('Enqueue Failing Task'),
          ),
          ElevatedButton(
            onPressed: () => queue.retryFailed(),
            child: const Text('Retry Failed Tasks'),
          ),
        ],
      ),
    );
  }
}
