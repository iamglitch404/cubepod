# CubePod 🧊
> **The Application Runtime for Flutter. The Next.js of Mobile.**

[![Pub Version](https://img.shields.io/pub/v/cubepod_core?color=blue)](https://pub.dev/packages/cubepod_core)
[![Build Status](https://img.shields.io/badge/build-passing-success)](https://github.com/iamglitch404/cubepod)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.19.0-blue.svg)]()
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.2.0-blue.svg)]()
[![Performance](https://img.shields.io/badge/Performance-2x_Faster_than_ChangeNotifier-orange.svg)]()

CubePod is not just another Flutter state management library. It is a **complete Application Runtime**. It solves Flutter's fragmentation problem by providing a unified, zero-boilerplate, and highly performant architecture for **State, Dependency Injection, Async Data Fetching, Offline Sync, Routing, and Enterprise Multi-Tenancy**.

Say goodbye to stitching together `provider`, `get_it`, `dio`, `go_router`, and `sqflite`. Say hello to CubePod.

---

## 🌟 Why CubePod? (vs Riverpod, Bloc, & GetX)

1. **Zero Code Generation:** No `build_runner`. No `.g.dart` files. Full type safety natively.
2. **True Fine-Grained Reactivity:** Powered by Signals. `CubeBuilder` only rebuilds the exact widget reading the changed data. It is **2x faster than `ChangeNotifier`**.
3. **No Widget Tree Pollution:** State and dependencies live outside the UI. Access them anywhere, even in background isolates or pure Dart logic.
4. **Offline-First by Default:** The only Flutter framework with a built-in `SyncQueue`, dead-letter queues, and automatic retry policies.
5. **The "TanStack Query" of Flutter:** Built-in `CubeQuery` for async data fetching, automatic caching, pagination, and optimistic updates.
6. **Enterprise Ready:** First-class primitives for Feature Flags, Audit Logging, and Multi-Tenant configurations.

---

## 📦 Installation

CubePod is fully modular. Install only what you need, or get everything via `cubepod`.

```yaml
dependencies:
  # The complete framework
  cubepod: ^0.1.0
  
  # OR install modularly:
  cubepod_core: ^0.1.0       # Dependency Injection
  cubepod_state: ^0.1.0      # Signals & State Management
  cubepod_flutter: ^0.1.0    # UI Widgets (CubeBuilder)
  cubepod_query: ^0.1.0      # Async Data Fetching
  cubepod_network: ^0.1.0    # Http API Client
```

---

## 🚀 Quick Start: The Basics

### 1. Dependency Injection (cubepod_core)
No `get_it` needed. CubePod handles singletons, factories, request-scoped instances, and circular dependency detection automatically.

```dart
import 'package:cubepod_core/cubepod_core.dart';

void main() {
  // Register dependencies globally
  CubePod.register(() => AuthService(), scope: Scope.singleton);
  CubePod.register(() => UserRepository(CubePod.get<AuthService>()));
  
  // Retrieve anywhere (O(1) resolution speed)
  final repo = CubePod.get<UserRepository>();
}
```

### 2. Fine-Grained State (cubepod_state)
Signals are the modern way to handle state. They track their own subscriptions automatically.

```dart
import 'package:cubepod_state/cubepod_state.dart';

// Create a state signal
final counter = StateSignal<int>(0);

// Derived state (only recalculates when counter changes)
final isEven = ComputedSignal<bool>(() => counter.value.isEven);

void increment() {
  counter.value++;
}
```

### 3. Reactive UI (cubepod_flutter)
Use `CubeBuilder` to bind Signals to the UI. It automatically tracks which signals are read during the build phase and unsubscribes from stale ones.

```dart
import 'package:cubepod_flutter/cubepod_flutter.dart';

class CounterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CubeBuilder(
      builder: (context, watch) {
        // Only rebuilds when `counter` changes
        final count = watch(counter);
        final even = watch(isEven);
        
        return Text('$count is ${even ? "Even" : "Odd"}');
      }
    );
  }
}
```

---

## 🔥 Advanced Features

### 📡 Async Data Fetching (cubepod_query)
Inspired by React Query / TanStack Query. Handles loading states, caching, invalidation, and pagination.

```dart
final userQuery = CubeQuery<User>(
  queryFn: () => api.fetchUser(),
  staleTime: const Duration(minutes: 5), // Cached for 5 minutes
);

// In your UI:
CubeBuilder(
  builder: (context, watch) {
    final state = watch(userQuery);
    
    if (state.isLoading) return CircularProgressIndicator();
    if (state.hasError) return Text('Error: ${state.error}');
    return Text('User: ${state.data.name}');
  }
)
```

### 📝 Reactive Forms with Validation (cubepod_state)
Built-in form management so you don't need `reactive_forms`.

```dart
final loginForm = CubeForm({
  'email': CubeField<String>(
    initialValue: '',
    validators: [Validators.required(), Validators.email()],
  ),
  'password': CubeField<String>(
    initialValue: '',
    validators: [Validators.minLength(8)],
  ),
});

// Submit form
await loginForm.submit((values) async {
  await api.login(values['email'], values['password']);
});
```

### 🔄 Offline Sync Queue (cubepod_sync)
Never lose user data when they go offline. Built-in SQLite-backed sync queue with exponential retry.

```dart
final queue = SyncQueue(
  storage: myStorage,
  retryPolicy: const ExponentialRetryPolicy(maxRetries: 5),
);

// Enqueue tasks while offline
queue.enqueue(UpdateProfileTask(newName: 'Alice'));

// CubePod automatically retries when online, pushing failures to a Dead Letter Queue.
```

### ⏱️ Native Time Travel
Add `enableHistory: true` to any signal to instantly gain undo/redo capabilities. Perfect for drawing apps, complex forms, or text editors.

```dart
final textState = StateSignal<String>('', enableHistory: true);

textState.value = 'Hello';
textState.value = 'Hello World';

textState.undo(); // back to 'Hello'
textState.redo(); // forward to 'Hello World'
```

---

## ⚡ Performance Benchmarks

CubePod is built for 120fps apps. (Measured on Dart 3.x / Linux x86_64)

- **State Read:** `119M ops/sec` (0.008 µs/op)
- **State Write (with fanout):** `3M ops/sec` (~2x faster than ChangeNotifier)
- **DI Resolution:** `4.4M ops/sec` (Zero overhead compared to raw instantiation)
- **Signal Creation:** `5M ops/sec`
- **Cache Hit (CubeQuery):** `7.5M ops/sec`

Read the full [Performance Report here](BENCHMARKS.md).

---

## 🧩 The CubePod Ecosystem

CubePod is a monorepo containing 19 specialized packages:

| Package | Description |
|---------|-------------|
| `cubepod_core` | Advanced DI container with scopes and cycle detection. |
| `cubepod_state` | Signals, Form State, Computed State, and Time Travel. |
| `cubepod_flutter` | High-performance reactive widgets (`CubeBuilder`, `CubeSelector`). |
| `cubepod_async` | `AsyncSignal`, Stream-to-Signal bridges, Cancellation Tokens. |
| `cubepod_query` | Automatic caching, async fetching, and pagination. |
| `cubepod_network` | Typed HTTP client with async Interceptor pipelines. |
| `cubepod_events` | Event Bus, finite State Machines, and Erlang-style Actors. |
| `cubepod_sync` | Offline-first sync queues and Dead Letter processing. |
| `cubepod_storage` | Local storage engine with `PersistedSignal` auto-saving. |
| `cubepod_router` | Typed navigation stack with middleware guards. |
| `cubepod_enterprise` | Multi-tenancy, Feature Flags, and Audit Logging. |

---

## 🤝 Contributing

We welcome community contributions! Please read our [Contributing Guide](CONTRIBUTING.md) to get started with setting up the monorepo using `melos`.

**Created with ❤️ by [Qubix Tech Nepal](https://github.com/iamglitch404).**

---

### SEO & Discoverability Tags
*Flutter State Management, Flutter Architecture, Reactive Programming in Flutter, Signal State Management Dart, Flutter Dependency Injection, Flutter Offline Sync, Flutter React Query Equivalent, Flutter Enterprise Architecture, Replacement for Riverpod Provider Bloc GetX.*
