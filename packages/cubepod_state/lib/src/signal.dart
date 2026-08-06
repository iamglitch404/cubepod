import 'package:cubepod_core/cubepod_core.dart';
import 'package:meta/meta.dart';
import 'transaction.dart';
import 'dart:async';

part 'signal_config.dart';
part 'state_signal.dart';
part 'computed_signal.dart';
part 'effect.dart';

abstract class Signal<T> {
  T get value;
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
  void removeObserver(SignalObserver observer);
  void dispose();
}

typedef VoidCallback = void Function();

// Thread-local (Dart-isolate-local) current observer, used for automatic
// dependency tracking during computed/effect evaluation.
SignalObserver? _currentObserver;

int _signalIdCounter = 0;

abstract class SignalObserver {
  void onDependencyChanged();
  void trackDependency(Signal<dynamic> signal);
  bool get requiresImmediateInvalidation;
}
