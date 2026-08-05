# cubepod_events

Event-driven architecture for CubePod — an event bus and Actor-model state machines.

## What's inside

- **`EventBus`** — pub/sub event bus for decoupled communication between services
- **`Actor<S, E>`** — finite state machine with typed states and typed events

## Install

```yaml
dependencies:
  cubepod_events: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_events/cubepod_events.dart';

// Event bus
EventBus.emit(UserLoggedIn(userId: '123'));
EventBus.on<UserLoggedIn>((event) => print('Welcome ${event.userId}'));

// Actor (state machine)
final auth = Actor<AuthState, AuthEvent>(initial: AuthState.idle);
auth.on<LoginPressed>((state, event) => AuthState.loading);
auth.on<LoginSuccess>((state, event) => AuthState.authenticated);
auth.send(LoginPressed(email: 'x@y.com', password: '...'));
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
