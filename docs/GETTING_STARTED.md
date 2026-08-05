# Getting Started with CubePod

Welcome to CubePod, the Application Runtime for Flutter. This guide will take you from zero to a fully reactive, dependency-injected app in under 5 minutes.

## 1. Installation

Add the umbrella package to your `pubspec.yaml`:

```yaml
dependencies:
  cubepod: ^0.1.0
```

Then, run:
```bash
flutter pub get
```

## 2. The Core Concept: Signals

Unlike `ChangeNotifier` or `Bloc`, CubePod uses **Signals**. A Signal is a wrapper around a value that notifies listeners automatically when it changes.

```dart
import 'package:cubepod/cubepod.dart';

// Create a signal
final counter = StateSignal<int>(0);

// Update it
counter.value++;
```

## 3. Binding to the UI

To make your Flutter widgets react to signal changes, use `CubeBuilder`. You do not need to pass the signal to the builder; the builder automatically detects which signals are read during the `watch()` phase.

```dart
import 'package:flutter/material.dart';
import 'package:cubepod/cubepod.dart';

class CounterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CubeBuilder(
          builder: (context, watch) {
            // The widget will rebuild ONLY when `counter.value` changes.
            final count = watch(counter);
            return Text('Count: $count');
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## 4. Dependency Injection (DI)

Most apps need to access services (like an API client) from anywhere. CubePod includes a blazing-fast O(1) DI container.

```dart
// 1. Define your service
class ApiService {
  Future<String> fetchUser() async => "Alice";
}

// 2. Register it in your main()
void main() {
  CubePod.register(() => ApiService(), scope: Scope.singleton);
  runApp(MyApp());
}

// 3. Access it anywhere
final api = CubePod.get<ApiService>();
```

## 5. Async Data Fetching (CubeQuery)

Instead of manually managing `isLoading` and `hasError` states, use `CubeQuery` to fetch, cache, and display remote data effortlessly.

```dart
final userQuery = CubeQuery<String>(
  queryFn: () => CubePod.get<ApiService>().fetchUser(),
  staleTime: const Duration(minutes: 5), // Cache the result
);

class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CubeBuilder(
      builder: (context, watch) {
        final state = watch(userQuery);
        
        if (state.isLoading) return CircularProgressIndicator();
        if (state.hasError) return Text('Failed to load');
        
        return Text('Welcome, ${state.data}!');
      }
    );
  }
}
```

## Next Steps
- Read about [Offline Syncing](https://github.com/iamglitch404/cubepod/blob/main/docs/SYNC.md)
- Learn how to structure [Enterprise Apps](ARCHITECTURE.md)
