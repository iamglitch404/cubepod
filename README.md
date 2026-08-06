# CubePod 🧊

> **Predictable dependency injection and fine-grained reactive state for Flutter.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.19.0-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.2.0-blue.svg)](https://dart.dev)

CubePod is a modular Flutter application framework built around two ideas:

1. **Dependencies should be explicit, scoped, and lifecycle-aware.** No service locator magic. No implicit globals. Register once, resolve anywhere — from ViewModels, background isolates, tests, and router guards alike.

2. **UI state should update only what changed.** The signal engine tracks which widget reads which value. Only that widget rebuilds. No `const` hacks. No manual `shouldRebuild` overrides.

---

## Why CubePod?

**Explicit lifetimes.** Every dependency declares whether it is a singleton (app-level), scoped (per-screen or per-feature), or a factory (fresh per use). The container enforces these rules automatically.

**Composable scopes.** Child containers inherit parent registrations but can override them locally. A test scope can swap out real services for fakes in two lines. A feature module can override a global logger with its own.

**Zero code generation.** No build_runner. No annotation processing. Wiring is plain Dart — readable, refactorable, debuggable.

**Signals-based reactivity.** Fine-grained `StateSignal` and `ComputedSignal` primitives. Automatic dependency tracking via `Effect`. Widgets rebuild at sub-widget granularity without `InheritedWidget` management.

**Tested under real apps.** CubePod was built by dogfooding — a Hacker News client and a Todo app were built with it before the API froze, exposing real usability issues before they became external problems.

---

## Packages

CubePod is a highly modular, multi-package ecosystem at v0.1.5.

| Package | What it does | Status |
|---|---|---|
| `cubepod` | Umbrella package exporting the core framework | ✅ Stable |
| `cubepod_core` | DI container — scopes, lifecycle, named registrations, circular dep detection | ✅ Stable |
| `cubepod_state` | Signals, computed values, effects, transactions, forms, streaming | ✅ Stable |
| `cubepod_flutter` | `CubeScope`, `CubeBuilder`, `CubeListenableBuilder`, `context.get<T>()` | ✅ Stable |
| `cubepod_testing` | `MockContainer`, `TestObserver` — testing utilities | ✅ Stable |
| `cubepod_query` | React Query style async data fetching and caching | ✅ Stable |
| `cubepod_network` | Type-safe HTTP API client with interceptors | ✅ Stable |
| `cubepod_router` | Integration with go_router for DI-aware navigation | ✅ Stable |
| `cubepod_sync` | Offline-first sync queues and storage hydration | ✅ Stable |
| `cubepod_storage` | Persisted signals and async memory/disk storage | ✅ Stable |
| `cubepod_events` | Event buses, actors, and finite state machines | ✅ Stable |
| `cubepod_async` | AsyncSignals, debouncing, and throttling utilities | ✅ Stable |
| `cubepod_resources` | Advanced resource pooling and lifecycle management | ✅ Stable |
| `cubepod_scheduler` | Priority queues and microtask scheduling | ✅ Stable |
| `cubepod_enterprise` | Feature flags, tenants, and audit logging | ✅ Stable |

---

## Installation

```yaml
dependencies:
  cubepod_core: ^0.1.5
  cubepod_state: ^0.1.5
  cubepod_flutter: ^0.1.5

dev_dependencies:
  cubepod_testing: ^0.1.5
```

---

## Quick Start

### 1. Dependency Injection

```dart
import 'package:cubepod_core/cubepod_core.dart';

void main() {
  // Register services at app startup
  CubePod.register<ApiService>((c) => ApiService(), scope: Scope.singleton);
  CubePod.register<UserRepo>((c) => UserRepo(c.get<ApiService>()));

  runApp(const MyApp());
}
```

### 2. Scoped Dependencies (per-screen)

```dart
// In your router:
CubeScope(
  overrides: (c) {
    c.register<HomeViewModel>(
      (c) => HomeViewModel(c.get<UserRepo>()),
      scope: Scope.scoped,
    );
  },
  child: const HomeScreen(),
)

// In HomeScreen — the ViewModel is resolved and disposed with the scope:
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CubeListenableBuilder<HomeViewModel>(
      builder: (context, vm, child) => Text(vm.title),
    );
  }
}
```

### 3. Fine-Grained Reactive State

```dart
import 'package:cubepod_state/cubepod_state.dart';

final count = StateSignal(0);
final doubled = ComputedSignal(() => count.value * 2);

// In a widget — rebuilds only when count changes:
CubeBuilder(
  builder: (context, watch) => Text('${watch(count)} → ${watch(doubled)}'),
)
```

### 4. Testing

```dart
import 'package:cubepod_testing/cubepod_testing.dart';

setUp(() => MockContainer.reset());

test('HomeViewModel loads data', () async {
  MockContainer.overrideWith<ApiService>(FakeApiService());
  final vm = HomeViewModel(CubePod.get<ApiService>());
  await vm.load();
  expect(vm.items, isNotEmpty);
});
```

---

## Reference Applications

Two complete reference apps are included in the [`examples/`](https://github.com/iamglitch404/cubepod/tree/main/examples) directory:

- **[`hacker_news_app`](https://github.com/iamglitch404/cubepod/tree/main/examples/hacker_news_app)** — Stories, comments, search, infinite scroll, pull-to-refresh, offline cache, theme switching
- **[`todo_app`](https://github.com/iamglitch404/cubepod/tree/main/examples/todo_app)** — CRUD, local persistence, filters, undo/redo, optimistic updates, scoped ViewModels

---

## Performance

The DI container resolves dependencies in O(1) via a hash map and the signal engine propagates updates in O(n) where n is the number of direct listeners. Both are fast enough that they will never be your bottleneck — network latency, layout, and painting always dominate.

Detailed benchmarks are in [BENCHMARKS.md](BENCHMARKS.md).

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The monorepo uses `melos` — run `melos bootstrap` to get started.

---

## Status

CubePod is in **public alpha**. The core API is stable and used in two reference applications, but external feedback is actively sought before a v1.0 commitment. Breaking changes before v1.0 will be documented.

---

*Built by [iamglitch404](https://github.com/iamglitch404).*
