import 'package:cubepod/cubepod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cubepod umbrella', () {
    test('package exports are accessible', () {
      // Verify top-level exports resolve without error
      expect(CubePod, isNotNull);
    });
  });
}
