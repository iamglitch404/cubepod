import 'package:flutter/widgets.dart';
import 'package:cubepod_core/cubepod_core.dart';

extension CubeContext on BuildContext {
  T get<T extends Object>() => CubePod.get<T>();
}
