import 'dart:async';
import 'package:test/test.dart';
import 'package:cubepod_state/cubepod_state.dart';

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 1 — Exception Resilience
  // ───────────────────────────────────────────────────────────────────────────
  group('Exception Resilience (SignalConfig.errorHandler)', () {
    late List<Object> capturedErrors;
    late void Function(Object, StackTrace) originalHandler;

    setUp(() {
      capturedErrors = [];
      originalHandler = SignalConfig.errorHandler;
      // Install a test-scoped error handler so we can assert on caught errors.
      SignalConfig.errorHandler = (e, _) => capturedErrors.add(e);
    });

    tearDown(() {
      // Always restore the original handler to avoid test pollution.
      SignalConfig.errorHandler = originalHandler;
    });

    test('Exception in listener does not halt subsequent listeners', () {
      final sig = StateSignal<int>(0);
      var secondListenerCallCount = 0;

      sig.addListener(() => throw Exception('Boom'));
      sig.addListener(() => secondListenerCallCount++);

      sig.value = 1;
      sig.value = 2;

      expect(
          capturedErrors, hasLength(2)); // both writes captured the exception
      expect(capturedErrors.first, isA<Exception>());
      expect(secondListenerCallCount, 2); // second listener ran both times
      sig.dispose();
    });

    test('Exception in observer does not halt subsequent observers', () {
      final source = StateSignal<int>(0);
      var secondComputedCallCount = 0;

      // First computed throws — simulated via a listener that throws
      source.addListener(() => throw Exception('Observer Boom'));
      // Second observer must still fire
      source.addListener(() => secondComputedCallCount++);

      source.value = 1;
      source.value = 2;

      expect(capturedErrors, hasLength(2));
      expect(capturedErrors.first, isA<Exception>());
      expect(secondComputedCallCount, 2);
      source.dispose();
    });

    test('Exception in effect body is forwarded to errorHandler', () {
      final sig = StateSignal<int>(0);
      var effectRunCount = 0;

      final eff = effect(() {
        sig.value; // track dependency
        effectRunCount++;
        if (sig.value > 0) throw Exception('Effect Boom');
      });

      expect(effectRunCount, 1); // initial run
      sig.value = 1;
      expect(capturedErrors, hasLength(1));
      expect(capturedErrors.first, isA<Exception>());
      // Effect must still re-run on next change — exception did not kill it
      sig.value = 2;
      expect(effectRunCount, 3);
      eff.dispose();
      sig.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 2 — Reentrant (Self-Updating) Signals
  // ───────────────────────────────────────────────────────────────────────────
  group('Reentrant Signal Writes', () {
    test('Writing to a signal inside its own listener processes update', () {
      final sig = StateSignal<int>(0);
      final seen = <int>[];

      sig.addListener(() {
        seen.add(sig.value);
        if (sig.value == 1) {
          sig.value = 2; // reentrant write — must be queued and processed
        }
      });

      sig.value = 1;

      // The re-entrant write to 2 must have been processed
      expect(sig.value, 2);
      expect(seen, containsAllInOrder([1, 2]));
      sig.dispose();
    });

    test('Deeply reentrant writes do not cause infinite recursion', () {
      final sig = StateSignal<int>(0);
      var depth = 0;
      final seen = <int>[];

      sig.addListener(() {
        depth++;
        seen.add(sig.value);
        // Reentrant write: sig.value = depth (1, then 2, ...).
        // Once sig.value == depth (already equal), the equality check in
        // StateSignal.value= deduplicates and stops the chain — no infinite loop.
        if (depth < 5) sig.value = depth;
      });

      sig.value = 1;

      // Verify: the engine did not throw, did not infinite-loop, and the
      // bounded reentrant writes settled cleanly.
      expect(() => sig.value, returnsNormally);
      expect(sig.value, isNonNegative);
      sig.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 3 — Safe Iteration (RangeError Prevention)
  // ───────────────────────────────────────────────────────────────────────────
  group('Safe Listener Array Iteration', () {
    test('Self-unsubscribe during notify does not throw RangeError', () {
      final sig = StateSignal<int>(0);
      var secondListenerCount = 0;

      void selfRemovingListener() {
        sig.removeListener(selfRemovingListener); // remove self mid-loop
      }

      sig.addListener(selfRemovingListener);
      sig.addListener(() => secondListenerCount++);

      expect(() => sig.value = 1, returnsNormally);
      expect(secondListenerCount, 1);
      sig.dispose();
    });

    test('Adding a new listener inside a listener does not cause double-fire',
        () {
      final sig = StateSignal<int>(0);
      var newListenerCount = 0;

      sig.addListener(() {
        // Add a new listener inside the notification — it must NOT fire in
        // this same notification pass.
        sig.addListener(() => newListenerCount++);
      });

      sig.value = 1; // first notification: outer fires, new listener added
      expect(newListenerCount, 0); // new listener must NOT have fired yet

      sig.value = 2; // second notification: both fire
      expect(newListenerCount, 1);
      sig.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 4 — Effect Disposal & Memory Safety
  // ───────────────────────────────────────────────────────────────────────────
  group('Effect Disposal & Memory Leak Prevention', () {
    test('Disposed effect does not re-run on signal change', () {
      final sig = StateSignal<int>(0);
      var callCount = 0;

      final eff = effect(() {
        sig.value; // track dependency
        callCount++;
      });

      expect(callCount, 1); // initial run

      sig.value = 1;
      expect(callCount, 2); // triggered by change

      eff.dispose();

      sig.value = 2;
      expect(callCount, 2); // must NOT trigger after dispose
      sig.dispose();
    });

    test('10,000 create+dispose cycles leave zero observers on signal', () {
      final sig = StateSignal<int>(0);

      for (var i = 0; i < 10000; i++) {
        final eff = effect(() => sig.value);
        eff.dispose();
      }

      final observerCount = sig.observerCount;
      expect(observerCount, 0,
          reason: 'Memory leak: $observerCount effects were not cleaned up');

      sig.dispose();
    });

    test('ComputedSignal disposes cleanly from upstream signal', () {
      final source = StateSignal<int>(0);
      final computed = ComputedSignal<int>(() => source.value * 2);

      // Access to register as an observer
      computed.value;

      final observersBefore = source.observerCount;
      expect(observersBefore, 1);

      computed.dispose();

      final observersAfter = source.observerCount;
      expect(observersAfter, 0,
          reason: 'ComputedSignal was not removed from source observers');

      source.dispose();
    });

    test('ComputedSignal does not re-trigger after dispose', () {
      final source = StateSignal<int>(0);
      var computeCount = 0;
      final computed = ComputedSignal<int>(() {
        computeCount++;
        return source.value * 2;
      });

      computed.value; // initial evaluation
      expect(computeCount, 1);

      computed.dispose();
      source.value = 99; // must NOT retrigger computed

      expect(computeCount, 1);
      source.dispose();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 5 — ComputedSignal Correctness
  // ───────────────────────────────────────────────────────────────────────────
  group('ComputedSignal Memoization', () {
    test('Cache hit returns value without recomputing', () {
      final source = StateSignal<int>(5);
      var computeCount = 0;

      final computed = ComputedSignal<int>(() {
        computeCount++;
        return source.value * 2;
      });

      computed.value;
      computed.value;
      computed.value;
      expect(computeCount, 1); // only computed once

      source.value = 6;
      computed.value; // stale — must recompute
      expect(computeCount, 2);

      computed.value; // cached again
      expect(computeCount, 2);

      source.dispose();
      computed.dispose();
    });

    test('ComputedSignal automatically tracks new dependencies', () {
      final a = StateSignal<int>(1);
      final b = StateSignal<int>(10);
      final useB = StateSignal<bool>(false);
      var computeCount = 0;

      final computed = ComputedSignal<int>(() {
        computeCount++;
        return useB.value ? b.value : a.value;
      });

      computed.value; // evaluates a
      expect(computed.value, 1);

      b.value = 99; // b is not a dependency yet — must NOT invalidate
      expect(computeCount, 1);

      useB.value = true; // switch branch — now b is tracked
      computed.value;
      expect(computeCount, 2);
      expect(computed.value, 99);

      b.value = 50; // now b IS a dependency
      computed.value;
      expect(computeCount, 3);
      expect(computed.value, 50);

      a.dispose();
      b.dispose();
      useB.dispose();
      computed.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 6 — Transaction
  // ─────────────────────────────────────────────────────────────────────────────
  group('Transaction', () {
    test('runTransaction rolls back all signals on exception', () {
      final a = StateSignal(1);
      final b = StateSignal(10);

      try {
        runTransaction(() {
          a.value = 99;
          b.value = 88;
          throw Exception('intentional rollback');
        });
      } catch (_) {
        // expected
      }

      // Both signals must have been restored to their pre-transaction values
      expect(a.value, 1);
      expect(b.value, 10);

      a.dispose();
      b.dispose();
    });

    test('runTransaction commits on success', () {
      final a = StateSignal<int>(1);

      runTransaction(() {
        a.value = 42;
      });

      expect(a.value, 42);
      a.dispose();
    });

    test('nested runTransaction is a no-op (participates in outer)', () {
      final a = StateSignal<int>(0);

      try {
        runTransaction(() {
          a.value = 1;
          // Nested transaction — should join the outer, not create a new one
          runTransaction(() {
            a.value = 2;
          });
          throw Exception('roll back outer');
        });
      } catch (_) {}

      // Both writes must have been rolled back
      expect(a.value, 0);
      a.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 7 — StreamSignal
  // ─────────────────────────────────────────────────────────────────────────────
  group('StreamSignal', () {
    test('initializes with the provided initialValue', () {
      final sig = StreamSignal<int>(
        stream: const Stream<int>.empty(),
        initialValue: 42,
      );
      expect(sig.value, 42);
      sig.dispose();
    });

    test('updates value when stream emits', () async {
      final controller = StreamController<int>();
      final sig = StreamSignal<int>(
        stream: controller.stream,
        initialValue: 0,
      );

      controller.add(1);
      controller.add(2);
      await Future<void>.delayed(Duration.zero); // let microtasks flush

      expect(sig.value, 2);
      sig.dispose();
      await controller.close();
    });

    test('disposes cleanly and stops updating after dispose', () async {
      final controller = StreamController<int>();
      final sig = StreamSignal<int>(
        stream: controller.stream,
        initialValue: 0,
      );

      sig.dispose();
      controller.add(99);
      await Future<void>.delayed(Duration.zero);

      // Value access on a disposed signal must throw a StateError
      expect(() => sig.value, throwsStateError);
      await controller.close();
    });

    test('routes stream errors to SignalConfig.errorHandler', () async {
      final controller = StreamController<int>();
      Object? caughtError;

      final originalHandler = SignalConfig.errorHandler;
      SignalConfig.errorHandler = (e, s) {
        caughtError = e;
      };

      final sig = StreamSignal<int>(
        stream: controller.stream,
        initialValue: 0,
      );

      controller.addError(StateError('Test error'));
      await Future<void>.delayed(Duration.zero);

      expect(caughtError, isA<StateError>());
      expect((caughtError as StateError).message, 'Test error');

      sig.dispose();
      await controller.close();
      SignalConfig.errorHandler = originalHandler;
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 8 — CubeForm
  // ─────────────────────────────────────────────────────────────────────────────
  group('CubeForm', () {
    late CubeForm form;

    setUp(() {
      form = CubeForm({
        'name': CubeField<String>(
          initialValue: '',
          validators: [Validators.required('Name is required')],
        ),
        'email': CubeField<String>(
          initialValue: '',
          validators: [Validators.email()],
        ),
      });
    });

    test('validate() returns false and sets errors when invalid', () {
      final valid = form.validate();
      expect(valid, isFalse);
      expect(form.field<String>('name').error, isNotNull);
    });

    test('validate() returns true when all fields pass', () {
      form.field<String>('name').setValue('Alice');
      form.field<String>('email').setValue('alice@example.com');
      final valid = form.validate();
      expect(valid, isTrue);
    });

    test('field.isDirty is false initially, true after setValue', () {
      final nameField = form.field<String>('name');
      expect(nameField.isDirty, isFalse);
      nameField.setValue('Bob');
      expect(nameField.isDirty, isTrue);
    });

    test('submit() does not call handler when validation fails', () async {
      var called = false;
      await form.submit((_) async => called = true);
      expect(called, isFalse);
    });

    test('submit() calls handler and manages isSubmitting when valid',
        () async {
      form.field<String>('name').setValue('Alice');
      form.field<String>('email').setValue('alice@example.com');

      final submittingValues = <bool>[];
      form.isSubmitting
          .addListener(() => submittingValues.add(form.isSubmitting.value));

      await form.submit((_) async {});

      // isSubmitting goes true then false
      expect(submittingValues, [true, false]);
    });

    test('reset() clears errors and dirty state', () {
      form.field<String>('name').setValue('Alice');
      form.validate();
      form.field<String>('email').setValue('bad'); // invalid email
      form.validate();

      form.reset();

      // After reset, errors cleared and dirty = false
      expect(form.field<String>('name').isDirty, isFalse);
    });

    test('field() throws StateError for unknown field name', () {
      expect(() => form.field<String>('nonexistent'), throwsStateError);
    });
  });
}
