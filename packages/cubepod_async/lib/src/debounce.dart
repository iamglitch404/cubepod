import 'dart:async';
import 'package:cubepod_state/cubepod_state.dart';

extension SignalDebounceExt<T> on Signal<T> {
  Signal<T> debounce(Duration duration) {
    final debouncedSignal = StateSignal<T>(value);
    Timer? timer;

    effect(() {
      final newValue = value;
      timer?.cancel();
      timer = Timer(duration, () {
        debouncedSignal.value = newValue;
      });
    });

    return debouncedSignal;
  }

  Signal<T> throttle(Duration duration) {
    final throttledSignal = StateSignal<T>(value);
    bool isThrottling = false;

    effect(() {
      final newValue = value;
      if (!isThrottling) {
        throttledSignal.value = newValue;
        isThrottling = true;
        Timer(duration, () {
          isThrottling = false;
        });
      }
    });

    return throttledSignal;
  }
}
