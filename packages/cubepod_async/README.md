# cubepod_async

Async utilities for CubePod — cancellation, retry, debounce, and more.

## What's inside

- **`CancellationToken`** — cancel any in-flight async operation cleanly
- **`RetryPolicy`** — configurable exponential backoff retry logic
- **`Debounce`** — delay execution until input stops changing
- **`AsyncSignal<T>`** — reactive wrapper for async state (loading/data/error)
- **`AsyncStreamSignal<T>`** — reactive wrapper for stream-based async state

## Install

```yaml
dependencies:
  cubepod_async: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_async/cubepod_async.dart';

// Cancellable fetch
final token = CancellationToken();
final data = await fetchUser(token: token);
token.cancel(); // cancels if still running

// Retry with backoff
final policy = RetryPolicy(maxAttempts: 3, delay: Duration(seconds: 2));
await policy.run(() => api.uploadFile(file));

// Debounce search input
final search = Debounce<String>(delay: Duration(milliseconds: 300));
search.call(query, () => runSearch(query));
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
