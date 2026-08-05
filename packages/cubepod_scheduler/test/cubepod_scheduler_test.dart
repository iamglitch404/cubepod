import 'dart:async';
import 'package:cubepod_scheduler/cubepod_scheduler.dart';
import 'package:test/test.dart';

void main() {
  group('CubeScheduler', () {
    test('schedule() with high priority runs via microtask', () async {
      bool ran = false;
      CubeScheduler.schedule(() => ran = true, priority: SchedulePriority.high);
      await Future.delayed(Duration.zero);
      expect(ran, isTrue);
    });

    test('schedule() with normal priority runs via Timer', () async {
      bool ran = false;
      CubeScheduler.schedule(
        () => ran = true,
        priority: SchedulePriority.normal,
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(ran, isTrue);
    });

    test('schedule() with idle priority runs after a delay', () async {
      bool ran = false;
      CubeScheduler.schedule(() => ran = true, priority: SchedulePriority.idle);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(ran, isTrue);
    });

    test('periodic() fires callback repeatedly', () async {
      int count = 0;
      final completer = Completer<void>();

      final timer = CubeScheduler.periodic(const Duration(milliseconds: 5), (
        _,
      ) {
        count++;
        if (count >= 3 && !completer.isCompleted) {
          completer.complete();
        }
      });

      await completer.future.timeout(const Duration(seconds: 2));
      timer.cancel();
      expect(count, greaterThanOrEqualTo(3));
    });
  });
}
