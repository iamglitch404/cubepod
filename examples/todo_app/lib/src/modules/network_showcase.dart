import 'package:flutter/material.dart';
import 'package:cubepod_network/cubepod_network.dart';
import 'package:cubepod_query/cubepod_query.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';

class NetworkShowcasePage extends StatefulWidget {
  const NetworkShowcasePage({super.key});

  @override
  State<NetworkShowcasePage> createState() => _NetworkShowcasePageState();
}

class _NetworkShowcasePageState extends State<NetworkShowcasePage> {
  late final HttpApiClient client;
  late final CubeQuery<Map<String, dynamic>> query;

  @override
  void initState() {
    super.initState();
    client = HttpApiClient(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      timeout: const Duration(seconds: 5),
    );
    query = CubeQuery<Map<String, dynamic>>(
      queryFn: () async => {'id': 1, 'title': 'Test todo'},
    );
  }

  @override
  void dispose() {
    query.dispose();
    client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network & Query Showcase')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CubeBuilder(builder: (context, watch) {
              final state = watch(query);
              if (state.isLoading) return const CircularProgressIndicator();
              if (state.hasError) return Text('Error: ${state.error}');
              if (state.hasData) return Text('Data: ${state.data}');
              return const Text('Initial');
            }),
            ElevatedButton(
              onPressed: () => query.fetch(),
              child: const Text('Fetch'),
            ),
            ElevatedButton(
              onPressed: () => query.invalidate(),
              child: const Text('Invalidate Cache'),
            ),
          ],
        ),
      ),
    );
  }
}
