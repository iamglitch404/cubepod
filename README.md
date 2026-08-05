# CubePod 🧊

> **The Application Runtime for Flutter.**

[![Pub Version](https://img.shields.io/pub/v/cubepod?color=blue)](https://pub.dev/packages/cubepod)
[![Build Status](https://img.shields.io/badge/build-passing-success)](https://github.com/iamglitch404/cubepod)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.19.0-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.2.0-blue.svg)](https://dart.dev)

CubePod is not just another state management library. It's a complete application runtime for Flutter — a unified, modular ecosystem for **State, Dependency Injection, Async Data, Offline Sync, Routing, and more**. All designed to work together from day one.

Stop stitching together `provider`, `get_it`, `dio`, `go_router`, and `sqflite`. One framework. One pattern. Everything you need.

---

## Why CubePod?

**1. Fine-grained reactivity out of the box.**
CubePod is built on Signals. Only the widget that reads a changed value rebuilds — not its parent, not its siblings. No `const` hacks, no manual `shouldRebuild` overrides required.

**2. DI that lives outside the widget tree.**
Your services, repos, and use cases are registered once and resolved anywhere — in a background isolate, a router guard, or a pure Dart CLI test — with no `BuildContext` needed.

**3. Compile-time dependency verification.**
Add `cubepod_generator` and run `build_runner`. Your entire DI graph is verified at compile time. Missing registrations and circular dependencies become build errors, not crashes.

**4. Offline-first built in.**
`cubepod_sync` gives you a durable sync queue out of the box. User writes while offline are queued, retried with backoff, and replayed in order when the connection returns.

**5. Everything talks to each other.**
The state layer, the network client, the sync queue, and the router all share the same container and lifecycle. No glue code, no impedance mismatch between libraries.

---

## Installation

CubePod is fully modular. Use the umbrella package for everything, or pick only what you need.

```yaml
dependencies:
  # Everything at once
  cubepod: ^0.1.1

  # Or modularly
  cubepod_core: ^0.1.1       # DI container
  cubepod_state: ^0.1.1      # Signals & state
  cubepod_flutter: ^0.1.1    # UI widgets
  cubepod_query: ^0.1.1      # Async data fetching
  cubepod_network: ^0.1.1    # HTTP client
  cubepod_sync: ^0.1.1       # Offline sync queue
  cubepod_router: ^0.1.1     # Routing

  # Optional: compile-time DI generation
  cubepod_annotation: ^0.1.0

dev_dependencies:
  cubepod_generator: ^0.1.0  # optional, for @CubeInjectable
  build_runner: ^2.0.0
```

---

## Quick Start

### Dependency Injection

```dart
import 'package:cubepod_core/cubepod_core.dart';

void main() {
  CubePod.register<AuthService>(() => AuthService(), scope: Scope.singleton);
  CubePod.register<UserRepo>(() => UserRepo(CubePod.get<AuthService>()));

  runApp(MyApp());
}
```

Or use the generator to wire it all up automatically:

```dart
@CubeInjectable()
class AuthService { ... }

@CubeInjectable()
class UserRepo {
  final AuthService auth;
  UserRepo(this.auth);
}

@cubepodInit
void setup() => $initCubePod();
```

```bash
dart run build_runner build
```

### Reactive State

```dart
import 'package:cubepod_state/cubepod_state.dart';

final count = StateSignal(0);

void increment() => count.value++;
```

### Reactive UI

```dart
import 'package:cubepod_flutter/cubepod_flutter.dart';

CubeBuilder<int>(
  signal: count,
  builder: (context, value) => Text('$value'),
);
```

### Async Data Fetching

```dart
import 'package:cubepod_query/cubepod_query.dart';

final userQuery = CubeQuery<User>(
  key: 'profile',
  fetcher: () => api.getUser(),
  staleTime: Duration(minutes: 5),
);
```

### Offline Sync

```dart
import 'package:cubepod_sync/cubepod_sync.dart';

final queue = SyncQueue(storage: LocalStorage());

// When offline — queue the write
await queue.enqueue(SyncOperation(id: uuid(), type: 'update_user', payload: user.toJson()));

// When back online — replay everything
await queue.flush(handler: (op) => api.apply(op));
```

---

## Ecosystem

| Package | What it does |
|---|---|
| `cubepod_core` | DI container with scopes, lifecycle, and resource pooling |
| `cubepod_state` | Signals, computed values, forms, and time-travel (undo/redo) |
| `cubepod_flutter` | `CubeBuilder`, `CubeSelector`, `CubeListener` widgets |
| `cubepod_async` | Cancellation tokens, retry policies, debounce |
| `cubepod_query` | Async data fetching with caching and pagination |
| `cubepod_network` | Typed HTTP client with interceptors |
| `cubepod_events` | Event bus and Actor-model state machines |
| `cubepod_sync` | Offline-first sync queue with retry and dead-letter support |
| `cubepod_storage` | Persisted signals backed by SharedPreferences |
| `cubepod_router` | Declarative routing with route guards |
| `cubepod_scheduler` | Delayed and recurring task scheduling |
| `cubepod_resources` | Managed resource loading and caching |
| `cubepod_enterprise` | Feature flags, audit logging, multi-tenancy |
| `cubepod_testing` | Mock containers and test observers |
| `cubepod_annotation` | Annotations for compile-time DI generation |
| `cubepod_generator` | `build_runner` generator for compile-time DI verification |

---

## Performance

Benchmarks run on Dart 3.x / Linux x86_64:

- **State read:** > 100M ops/sec
- **State write (with fan-out):** ~14.7M ops/sec (insanely fast)
- **DI resolution:** 14.2M ops/sec (zero overhead)
- **Query cache hit:** 7.4M ops/sec

See [BENCHMARKS.md](BENCHMARKS.md) for the full report.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The monorepo uses `melos` — run `melos bootstrap` to get started.

---

*Built by [iamglitch404](https://github.com/iamglitch404).*
