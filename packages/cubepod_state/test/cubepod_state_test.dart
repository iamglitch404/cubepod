import 'package:cubepod_state/cubepod_state.dart';
import 'package:test/test.dart';

void main() {
  group('StateSignal', () {
    test('holds and returns initial value', () {
      final s = StateSignal<int>(42);
      expect(s.value, 42);
    });

    test('notifies listeners on value change', () {
      final s = StateSignal<int>(0);
      int callCount = 0;
      s.addListener(() => callCount++);
      s.value = 1;
      expect(callCount, 1);
      expect(s.value, 1);
    });

    test('does NOT notify when value is the same', () {
      final s = StateSignal<int>(5);
      int callCount = 0;
      s.addListener(() => callCount++);
      s.value = 5;
      expect(callCount, 0);
    });

    test('uses custom equals comparator', () {
      final s = StateSignal<List<int>>(
        [1, 2, 3],
        equals: (a, b) => a.length == b.length,
      );
      int callCount = 0;
      s.addListener(() => callCount++);
      s.value = [4, 5, 6]; // Same length — should not notify
      expect(callCount, 0);
      s.value = [1, 2]; // Different length — should notify
      expect(callCount, 1);
    });

    test('removeListener stops notifications', () {
      final s = StateSignal<int>(0);
      int callCount = 0;
      void listener() => callCount++;
      s.addListener(listener);
      s.value = 1;
      expect(callCount, 1);
      s.removeListener(listener);
      s.value = 2;
      expect(callCount, 1); // Not called again
    });

    test('update() applies updater function', () {
      final s = StateSignal<int>(10);
      s.update((v) => v * 2);
      expect(s.value, 20);
    });

    test('dispose() stops all notifications', () {
      final s = StateSignal<int>(0);
      int callCount = 0;
      s.addListener(() => callCount++);
      s.dispose();
      s.value = 99; // After dispose, _notify() should bail out
      expect(callCount, 0);
    });

    group('History / Time Travel', () {
      test('undo/redo works correctly', () {
        final s = StateSignal<int>(0, enableHistory: true);
        s.value = 1;
        s.value = 2;
        s.value = 3;
        expect(s.value, 3);
        s.undo();
        expect(s.value, 2);
        s.undo();
        expect(s.value, 1);
        s.redo();
        expect(s.value, 2);
      });

      test('branching truncates future history', () {
        final s = StateSignal<int>(0, enableHistory: true);
        s.value = 1;
        s.value = 2;
        s.undo(); // back to 1
        s.value = 99; // branch
        expect(s.history, [0, 1, 99]);
        // redo should not be possible (branched)
        s.redo();
        expect(s.value, 99);
      });

      test('undo at beginning does nothing', () {
        final s = StateSignal<int>(0, enableHistory: true);
        s.undo();
        expect(s.value, 0);
      });
    });
  });

  group('ComputedSignal', () {
    test('derives value lazily', () {
      final s = StateSignal<int>(2);
      int computeCount = 0;
      final doubled = ComputedSignal<int>(() {
        computeCount++;
        return s.value * 2;
      });

      expect(computeCount, 0); // Not computed yet
      expect(doubled.value, 4);
      expect(computeCount, 1);
      expect(doubled.value, 4); // Cached
      expect(computeCount, 1);

      s.value = 5;
      expect(computeCount, 1); // Still cached until read
      expect(doubled.value, 10);
      expect(computeCount, 2);
    });

    test('notifies downstream listeners when stale', () {
      final s = StateSignal<int>(1);
      final doubled = ComputedSignal<int>(() => s.value * 2);
      int callCount = 0;
      doubled.addListener(() => callCount++);
      // Access to build dependency graph
      doubled.value;

      s.value = 3;
      expect(callCount, 1);
    });
  });

  group('Effect', () {
    test('runs immediately and re-runs on dependency change', () {
      final s = StateSignal<int>(0);
      final seen = <int>[];
      final e = effect(() => seen.add(s.value));
      expect(seen, [0]);
      s.value = 1;
      expect(seen, [0, 1]);
      s.value = 2;
      expect(seen, [0, 1, 2]);
      e.dispose();
    });

    test('stops running after dispose()', () {
      final s = StateSignal<int>(0);
      int runCount = 0;
      final e = effect(() {
        s.value; // track
        runCount++;
      });
      expect(runCount, 1);
      e.dispose();
      s.value = 1;
      expect(runCount, 1); // Should NOT run again
    });
  });

  group('CubeForm', () {
    test('validates required fields', () {
      final form = CubeForm({
        'email': CubeField<String>(
          initialValue: '',
          validators: [Validators.required(), Validators.email()],
        ),
      });
      expect(form.validate(), isFalse);
      form.field<String>('email').setValue('test@example.com');
      expect(form.validate(), isTrue);
    });

    test('minLength validator', () {
      final field = CubeField<String>(
        initialValue: 'hi',
        validators: [Validators.minLength(5)],
      );
      expect(field.validate(), isFalse);
      field.setValue('hello world');
      expect(field.validate(), isTrue);
    });

    test('form.values returns all field values', () {
      final form = CubeForm({
        'name': CubeField<String>(initialValue: 'Alice'),
        'age': CubeField<int>(initialValue: 25),
      });
      final values = form.values;
      expect(values['name'], 'Alice');
      expect(values['age'], 25);
    });
  });

  group('StreamSignal', () {
    test('updates when stream emits', () async {
      final controller = Stream<int>.fromIterable([1, 2, 3]);
      final signal = StreamSignal<int>(stream: controller, initialValue: 0);
      await Future.delayed(Duration.zero);
      expect(signal.value, 3);
      signal.dispose();
    });
  });

  group('Transaction', () {
    test('rolls back all signals on error', () async {
      final a = StateSignal<int>(0);
      final b = StateSignal<int>(0);

      try {
        await runTransaction(() async {
          a.value = 10;
          b.value = 20;
          throw Exception('Rollback!');
        });
      } catch (_) {}

      expect(a.value, 0); // Rolled back
      expect(b.value, 0); // Rolled back
    });

    test('commits changes on success', () async {
      final a = StateSignal<int>(0);
      await runTransaction(() async {
        a.value = 99;
      });
      expect(a.value, 99);
    });
  });
}
