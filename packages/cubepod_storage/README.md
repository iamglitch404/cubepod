# cubepod_storage

Persistent reactive storage for CubePod. Wraps `SharedPreferences` (with support for custom backends) and exposes values as `StateSignal`s so your UI stays in sync automatically.

## What's inside

- **`StorageService`** — read/write key-value pairs with a typed API
- **`PersistedSignal<T>`** — a `StateSignal` that persists its value to disk

## Install

```yaml
dependencies:
  cubepod_storage: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_storage/cubepod_storage.dart';

// A signal that automatically saves to SharedPreferences
final themeMode = PersistedSignal<String>(
  key: 'theme_mode',
  defaultValue: 'light',
  storage: SharedPreferencesStorage(),
);

// Changing it saves to disk instantly
themeMode.value = 'dark';

// Reading it next app launch returns 'dark'
print(themeMode.value); // dark
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
