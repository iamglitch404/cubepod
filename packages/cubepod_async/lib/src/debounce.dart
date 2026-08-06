import 'dart:async';
import 'package:cubepod_state/cubepod_state.dart';

class _DebouncedSignal<T> extends StateSignal<T> {
  final Effect _effect;
  final Timer? Function() _getTimer;

  _DebouncedSignal(super.value, this._effect, this._getTimer);

  @override
  void dispose() {
    _effect.dispose();
    _getTimer()?.cancel();
    super.dispose();
  }
}

class _ThrottledSignal<T> extends StateSignal<T> {
  final Effect _effect;
  final Timer? Function() _getTimer;

  _ThrottledSignal(super.value, this._effect, this._getTimer);

  @override
  void dispose() {
    _effect.dispose();
    _getTimer()?.cancel();
    super.dispose();
  }
}

/// Adds debouncing and throttling capabilities to [Signal].
extension SignalDebounceExt<T> on Signal<T> {
  /// Returns a new [Signal] that only emits values after the source signal
  /// has stopped emitting for the given [duration].
  Signal<T> debounce(Duration duration) {
    Timer? timer;
    late _DebouncedSignal<T> debouncedSignal;

    final eff = effect(() {
      final newValue = value;
      timer?.cancel();
      timer = Timer(duration, () {
        debouncedSignal.value = newValue;
      });
    });

    debouncedSignal = _DebouncedSignal<T>(value, eff, () => timer);
    return debouncedSignal;
  }

  /// Returns a new [Signal] that emits values at most once per [duration].
  Signal<T> throttle(Duration duration) {
    bool isThrottling = false;
    Timer? timer;
    late _ThrottledSignal<T> throttledSignal;

    final eff = effect(() {
      final newValue = value;
      if (!isThrottling) {
        throttledSignal.value = newValue;
        isThrottling = true;
        timer = Timer(duration, () {
          isThrottling = false;
        });
      }
    });

    throttledSignal = _ThrottledSignal<T>(value, eff, () => timer);
    return throttledSignal;
  }
}
