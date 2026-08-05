# cubepod_resources

Managed resource loading for CubePod. Handles loading, caching, and releasing assets, configs, or any external resources tied to CubePod's scope lifecycle.

## Install

```yaml
dependencies:
  cubepod_resources: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_resources/cubepod_resources.dart';

final resources = CubePod.get<ResourceManager>();

// Load and cache a config file
final config = await resources.load<AppConfig>(
  key: 'app-config',
  loader: () => fetchRemoteConfig(),
);

// Release when no longer needed
resources.release('app-config');
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
