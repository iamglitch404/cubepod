# cubepod_testing

Testing utilities for CubePod — mock containers, test observers, and helpers for writing clean unit and widget tests.

## What's inside

- **`MockCubePod`** — replace real registrations with mocks for isolated tests
- **`TestObserver`** — capture state changes and DI events during a test

## Install

```yaml
dev_dependencies:
  cubepod_testing: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_testing/cubepod_testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    MockCubePod.setUp();
    MockCubePod.register<AuthService>(() => FakeAuthService());
  });

  tearDown(() => MockCubePod.reset());

  test('login sets user signal', () {
    final service = CubePod.get<AuthService>();
    service.login('user@example.com', 'password');
    expect(service.isLoggedIn.value, true);
  });
}
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
