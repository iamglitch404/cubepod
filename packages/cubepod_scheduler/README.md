# cubepod_scheduler

Task scheduling for CubePod. Run jobs on a delay, on a recurring interval, or at a specific time — all tied to CubePod's lifecycle so tasks are cancelled automatically when their scope is disposed.

## Install

```yaml
dependencies:
  cubepod_scheduler: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_scheduler/cubepod_scheduler.dart';

final scheduler = CubePod.get<Scheduler>();

// Run once after 5 seconds
scheduler.delay(Duration(seconds: 5), () => syncData());

// Run every 30 seconds
scheduler.repeat(Duration(seconds: 30), () => pingServer());

// Cancel all tasks when done
scheduler.cancelAll();
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.
