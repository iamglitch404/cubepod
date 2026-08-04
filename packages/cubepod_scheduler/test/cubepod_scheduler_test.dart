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
      final timer = CubeScheduler.periodic(
        const Duration(milliseconds: 10),
        (_) => count++,
      );
      await Future.delayed(const Duration(milliseconds: 55));
      timer.cancel();
      expect(count, greaterThanOrEqualTo(3));
    });
  });
}
