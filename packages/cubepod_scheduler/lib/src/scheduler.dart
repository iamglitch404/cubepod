import 'dart:async';

enum SchedulePriority { idle, normal, high }

class CubeScheduler {
  static void schedule(
    FutureOr<void> Function() task, {
    SchedulePriority priority = SchedulePriority.normal,
  }) {
    if (priority == SchedulePriority.high) {
      scheduleMicrotask(task);
    } else if (priority == SchedulePriority.normal) {
      Timer.run(task);
    } else {
      Future.delayed(const Duration(milliseconds: 50), task);
    }
  }

  static Timer periodic(Duration duration, void Function(Timer) callback) {
    return Timer.periodic(duration, callback);
  }
}
