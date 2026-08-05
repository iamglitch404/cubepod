# cubepod_state

Fine-grained reactive state for CubePod. Built on Signals — only the widgets that actually read a changed value rebuild.

## What's inside

- **`StateSignal<T>`** — reactive value that notifies listeners on change
- **`AsyncSignal<T>`** — signal with loading/error/data states for async ops
- **`StreamSignal<T>`** — wraps a `Stream` into a reactive signal
- **`Transaction`** — batch multiple signal changes into a single rebuild
- **`FormState`** — reactive form with field-level validation

## Install

```yaml
dependencies:
  cubepod_state: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_state/cubepod_state.dart';

final count = StateSignal(0);

// Read
print(count.value); // 0

// Write
count.value++;

// Listen
count.listen((val) => print('count changed: $val'));

// Batch updates — only one rebuild fires
transaction(() {
  count.value = 10;
  name.value = 'Alice';
});
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
