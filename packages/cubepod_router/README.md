# cubepod_router

Declarative routing for CubePod with first-class route guards and DI integration.

## What's inside

- **`CubeRouter`** — `RouterDelegate` with typed route stack
- **`CubeRouteGuard`** — protect routes based on auth state or feature flags
- **`CubeRouteParser`** — URL ↔ route mapping

## Install

```yaml
dependencies:
  cubepod_router: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_router/cubepod_router.dart';

final router = CubeRouter(
  routes: [
    CubeRoute(path: '/', builder: (_) => HomePage()),
    CubeRoute(
      path: '/settings',
      builder: (_) => SettingsPage(),
      guard: AuthGuard(), // redirects to /login if not logged in
    ),
  ],
);

MaterialApp.router(
  routerDelegate: router.delegate,
  routeInformationParser: router.parser,
);
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
