# cubepod_core

Dependency injection and the core container for CubePod. Everything else in the framework depends on this.

## What's inside

- **`CubePod`** — the global DI container with O(1) lookups
- **`Scope`** — singleton, factory, and scoped lifecycles
- **`ResourcePool`** — a reusable pool of expensive objects (e.g. DB connections)
- **`CubeObserver`** — hook into state/DI events for logging or analytics

## Install

```yaml
dependencies:
  cubepod_core: ^0.1.5
```

## Usage

```dart
import 'package:cubepod_core/cubepod_core.dart';

// Register
CubePod.register<AuthService>((c) => AuthService(), scope: Scope.singleton);
CubePod.register<UserRepo>((c) => UserRepo(c.get<AuthService>()));

// Resolve
final repo = CubePod.get<UserRepo>();

// Scoped lifetime (e.g. push on route open, pop on route close)
CubePod.pushScope();
CubePod.register<CartService>((c) => CartService(), scope: Scope.scoped);
CubePod.popScope(); // CartService is disposed here automatically
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
