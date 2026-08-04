import 'package:cubepod_sync/cubepod_sync.dart';
import 'package:test/test.dart';

void main() {
  group('SyncQueue', () {
    test('SyncQueue class is accessible', () {
      expect(SyncQueue, isNotNull);
    });

    test('SyncTaskStatus has expected values', () {
      expect(
          SyncTaskStatus.values,
          containsAll([
            SyncTaskStatus.pending,
            SyncTaskStatus.processing,
            SyncTaskStatus.failed,
          ]));
    });
  });
}
