# cubepod_network

HTTP networking for CubePod. A thin, interceptor-based API client that integrates cleanly with `cubepod_query` and `cubepod_sync`.

## What's inside

- **`ApiClient`** — abstract base for typed HTTP requests
- **`HttpApiClient`** — concrete implementation using `dart:io` / `http`
- **`Interceptor`** — middleware for logging, auth headers, retry logic

## Install

```yaml
dependencies:
  cubepod_network: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_network/cubepod_network.dart';

final client = HttpApiClient(
  baseUrl: 'https://api.myapp.com',
  interceptors: [
    AuthInterceptor(tokenProvider: () => getToken()),
    LoggingInterceptor(),
  ],
);

final response = await client.get<User>('/users/1', decoder: User.fromJson);
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
