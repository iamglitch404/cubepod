# cubepod_sync

Offline-first sync queue for CubePod. Queues local writes and replays them to your backend when the device comes back online. Handles retries, dead-letter queuing, and ordering automatically.

## What's inside

- **`SyncQueue`** — durable queue of pending sync operations
- **Automatic retry** with configurable backoff
- **Dead-letter queue** for operations that fail after all retries
- **Ordering guarantees** — operations replay in the order they were queued

## Install

```yaml
dependencies:
  cubepod_sync: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_sync/cubepod_sync.dart';

final queue = SyncQueue(storage: LocalStorage());

// Queue a write when offline
await queue.enqueue(SyncOperation(
  id: uuid(),
  type: 'update_profile',
  payload: user.toJson(),
));

// When back online, replay everything
await queue.flush(handler: (op) => api.apply(op));
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
