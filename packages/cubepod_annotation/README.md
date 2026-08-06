# cubepod_annotation

Annotation definitions for `cubepod_generator`. This is a lightweight package with no heavy dependencies — add it to your app, add `cubepod_generator` to dev dependencies, and you're done.

## Install

```yaml
dependencies:
  cubepod_annotation: ^0.1.5

dev_dependencies:
  cubepod_generator: ^0.1.5
  build_runner: ^2.0.0
```

## Usage

Annotate your service classes with `@CubeInjectable`:

```dart
import 'package:cubepod_annotation/cubepod_annotation.dart';

@CubeInjectable()          // singleton by default
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
```

Then mark your setup function and run the generator:

```dart
part 'main.g.dart';

@cubepodInit
void setup() => $initCubePod();
```

```bash
dart run build_runner build
```

The generator writes `di.g.dart` with a fully wired `$initCubePod()` — dependencies sorted, errors caught at compile time.

## Scopes

| Annotation | Behavior |
|---|---|
| `@singleton` | One instance for the entire app |
| `@factory` | New instance on every `CubePod.get<T>()` call |
| `@scoped` | One instance per active scope (e.g. per route) |
| `@CubeInjectable(name: 'secondary')` | Named registration for multiple impls |

See [cubepod](https://pub.dev/packages/cubepod) for the full framework docs.
