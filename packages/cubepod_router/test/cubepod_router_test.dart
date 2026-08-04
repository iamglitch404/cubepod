import 'package:cubepod_router/cubepod_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CubeRouter', () {
    test('can be instantiated with routes', () {
      final router = CubeRouter([]);
      expect(router, isNotNull);
    });
  });
}
