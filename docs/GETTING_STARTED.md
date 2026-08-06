# Getting Started with CubePod

This guide takes you from zero to a working, dependency-injected, reactive Flutter app in about ten minutes.

---

## 1. Installation

Add the packages you need to your `pubspec.yaml`:

```yaml
dependencies:
  cubepod_core: ^0.1.5      # DI container
  cubepod_state: ^0.1.5     # Signals and reactive state
  cubepod_flutter: ^0.1.5   # Flutter widgets

dev_dependencies:
  cubepod_testing: ^0.1.5   # Test utilities
```

Run:
```bash
flutter pub get
```

---

## 2. Dependency Injection

CubePod's DI container is the backbone of the framework. Register your services once at startup, then resolve them anywhere.

```dart
import 'package:cubepod_core/cubepod_core.dart';

void main() {
  // Singleton: one instance for the entire app lifetime
  CubePod.register<ApiService>((c) => ApiService(), scope: Scope.singleton);

  // Factory: a new instance on every get() call (the default)
  CubePod.register<Logger>((c) => ConsoleLogger());

  // Chained dependencies — the container passed to your factory
  // is the one performing the resolution, so overrides work correctly
  CubePod.register<UserRepo>((c) => UserRepo(c.get<ApiService>()));

  runApp(const MyApp());
}

// Resolve anywhere — no BuildContext needed:
final repo = CubePod.get<UserRepo>();
```

### Scoped Dependencies

Use `CubeScope` to create dependencies that live only as long as a screen:

```dart
// Wrap your route's widget in a CubeScope:
CubeScope(
  overrides: (c) {
    c.register<HomeViewModel>(
      (c) => HomeViewModel(c.get<UserRepo>()),
      scope: Scope.scoped, // one instance per scope, disposed with it
    );
  },
  child: const HomeScreen(),
)
```

Inside `HomeScreen`, resolve the ViewModel and it will be automatically disposed when the scope is removed from the tree.

---

## 3. Reactive State with Signals

Signals are the reactive primitive in CubePod. A signal wraps a value and notifies its listeners when it changes.

```dart
import 'package:cubepod_state/cubepod_state.dart';

// A writable signal
final count = StateSignal(0);

// Increment it anywhere
count.value++;

// A derived signal — recomputes only when its dependencies change
final doubled = ComputedSignal(() => count.value * 2);

// A side effect — re-runs automatically when tracked signals change
final eff = effect(() {
  print('Count is now: ${count.value}');
});

// Clean up when done
eff.dispose();
```

---

## 4. Reactive UI

### `CubeBuilder` — for Signal-based state

`CubeBuilder` automatically detects which signals you read during a build and subscribes to them. Only this widget rebuilds when they change.

```dart
import 'package:cubepod_flutter/cubepod_flutter.dart';

CubeBuilder(
  builder: (context, watch) {
    final count = watch(countSignal);
    return Text('Count: $count');
  },
)
```

### `CubeListenableBuilder` — for ChangeNotifier ViewModels

If your ViewModel extends `ChangeNotifier` (a common Flutter pattern), use `CubeListenableBuilder` to both resolve it from the DI container and subscribe to its changes:

```dart
CubeListenableBuilder<HomeViewModel>(
  builder: (context, vm, child) {
    if (vm.isLoading) return const CircularProgressIndicator();
    return ListView.builder(
      itemCount: vm.items.length,
      itemBuilder: (_, i) => Text(vm.items[i].title),
    );
  },
)
```

This is equivalent to — but more concise than:

```dart
final vm = context.get<HomeViewModel>();
return ListenableBuilder(
  listenable: vm,
  builder: (context, _) { ... },
);
```

---

## 5. Testing

`cubepod_testing` provides two utilities:

```dart
import 'package:cubepod_testing/cubepod_testing.dart';

setUp(() => MockContainer.reset()); // always reset between tests

test('loads data from service', () async {
  // Replace a real service with a fake one
  MockContainer.overrideWith<ApiService>(FakeApiService());

  final vm = HomeViewModel(CubePod.get<ApiService>());
  await vm.load();

  expect(vm.items, isNotEmpty);
});

test('signal emits expected values', () {
  final signal = StateSignal(0);
  final observer = TestObserver(signal);

  signal.value = 1;
  signal.value = 2;

  expect(observer.history, [0, 1, 2]);
  observer.dispose();
});
```

---

## Next Steps

- Read the [Architecture Guide](ARCHITECTURE.md) to understand the philosophy behind CubePod's design decisions.
- Explore the reference apps in `examples/` — [Hacker News](../examples/hacker_news_app) and [Todo](../examples/todo_app) — for complete, production-style examples.
- Check [CONTRIBUTING.md](../CONTRIBUTING.md) to contribute or file issues.
