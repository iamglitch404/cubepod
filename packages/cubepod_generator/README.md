# cubepod_generator

Compile-time code generator for CubePod. Scans your project for `@CubeInjectable` classes, verifies the entire dependency graph at build time, and generates a ready-to-use `$initCubePod()` function.

No runtime reflection. No hand-written registration boilerplate. Missing dependencies and circular deps are caught **before your app runs**.

## Install

```yaml
dev_dependencies:
  cubepod_generator: ^0.1.4
  build_runner: ^2.0.0
```

## How it works

1. You annotate classes with `@CubeInjectable` from `cubepod_annotation`.
2. You run `dart run build_runner build`.
3. The generator:
   - Finds every annotated class in your project.
   - Verifies all constructor dependencies are also registered. If not → **build fails with the exact class name**.
   - Checks for circular dependencies (A needs B, B needs A). If found → **build fails with the full cycle path**.
   - Sorts dependencies topologically so everything is registered in the right order.
   - Writes `di.g.dart` with a clean `$initCubePod()` function.

## Example

**`lib/di.dart`**
```dart
import 'package:cubepod_annotation/cubepod_annotation.dart';
import 'package:cubepod_core/cubepod_core.dart';

part 'di.g.dart';

@CubeInjectable()
class DatabaseService {
  DatabaseService();
}

@CubeInjectable(scope: CubeScope.factory)
class ApiClient {
  final DatabaseService db;
  ApiClient(this.db);
}

@CubeInjectable()
class AuthRepo {
  final ApiClient api;
  AuthRepo(this.api);
}

@cubepodInit
void setup() => $initCubePod();
```

Run the generator:
```bash
dart run build_runner build
```

**Generated `lib/di.g.dart`**
```dart
// GENERATED CODE — DO NOT EDIT

import 'package:cubepod_core/cubepod_core.dart';

void $initCubePod() {
  CubePod.register<DatabaseService>(() => DatabaseService(), scope: Scope.singleton);
  CubePod.register<ApiClient>(() => ApiClient(CubePod.get<DatabaseService>()), scope: Scope.factory);
  CubePod.register<AuthRepo>(() => AuthRepo(CubePod.get<ApiClient>()), scope: Scope.singleton);
}
```

Then call `setup()` in `main()`:
```dart
import 'package:flutter/material.dart';

void main() {
  setup(); // runs $initCubePod()
  runApp(const MyApp());
}
```

## Error examples

**Missing dependency:**
```
Missing registration: ApiClient depends on DatabaseService,
but DatabaseService is not annotated with @CubeInjectable.
```

**Circular dependency:**
```
Circular dependency: ServiceA → ServiceB → ServiceA
```

See [cubepod](https://pub.dev/packages/cubepod) for the full framework docs.
