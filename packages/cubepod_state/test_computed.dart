import 'package:cubepod_state/cubepod_state.dart';

void main() {
  final source = StateSignal<int>(0);
  final computed = ComputedSignal<int>(() => source.value * 2);

  computed.value;
  computed.dispose();

  // This simulates the parent calling onDependencyChanged after the computed is disposed
  // (e.g., if it was disposed mid-notification loop)
  computed.onDependencyChanged();

  print('Success, no crash!');
}
