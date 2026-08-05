# cubepod_flutter

Flutter UI widgets for CubePod. Connects `StateSignal` to your widget tree with surgical rebuilds — only the widget reading the changed value updates.

## What's inside

- **`CubeBuilder<T>`** — rebuilds when a `StateSignal` changes
- **`CubeSelector<T, R>`** — rebuilds only when a derived value changes
- **`CubeListener<T>`** — runs a side effect when a signal changes (no rebuild)
- **`CubeConsumer<T>`** — combines `CubeBuilder` + `CubeListener`

## Install

```yaml
dependencies:
  cubepod_flutter: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_flutter/cubepod_flutter.dart';

final count = StateSignal(0);

// Rebuilds only when count changes
CubeBuilder<int>(
  signal: count,
  builder: (context, value) => Text('$value'),
);

// Rebuilds only when the length of the list changes, not the list itself
CubeSelector<List<Item>, int>(
  signal: items,
  selector: (list) => list.length,
  builder: (context, len) => Text('$len items'),
);
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
