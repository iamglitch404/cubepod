import 'package:cubepod_storage/cubepod_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryStorage', () {
    late StorageService storage;

    setUp(() async {
      storage = MemoryStorage();
      await storage.init();
    });

    test('setString and getString round-trip', () async {
      await storage.setString('key', 'value');
      expect(storage.getString('key'), 'value');
    });

    test('getString returns null for missing key', () {
      expect(storage.getString('missing'), isNull);
    });

    test('remove deletes a key', () async {
      await storage.setString('key', 'value');
      await storage.remove('key');
      expect(storage.getString('key'), isNull);
    });

    test('clear removes all keys', () async {
      await storage.setString('a', '1');
      await storage.setString('b', '2');
      await storage.clear();
      expect(storage.getString('a'), isNull);
      expect(storage.getString('b'), isNull);
    });

    test('multiple keys are independent', () async {
      await storage.setString('x', 'hello');
      await storage.setString('y', 'world');
      expect(storage.getString('x'), 'hello');
      expect(storage.getString('y'), 'world');
    });
  });
}
