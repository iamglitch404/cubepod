import 'package:cubepod_resources/cubepod_resources.dart';
import 'package:test/test.dart';

class _FakeFileResource extends Resource<String> {
  int createCount = 0;
  int disposeCount = 0;

  @override
  Future<String> create() async {
    createCount++;
    return 'open_file_handle';
  }

  @override
  Future<void> dispose(String instance) async {
    disposeCount++;
  }
}

void main() {
  group('Resource', () {
    test('acquire() creates the resource on first call', () async {
      final resource = _FakeFileResource();
      final handle = await resource.acquire();
      expect(handle, 'open_file_handle');
      expect(resource.createCount, 1);
    });

    test('acquire() returns the same instance on subsequent calls', () async {
      final resource = _FakeFileResource();
      final a = await resource.acquire();
      final b = await resource.acquire();
      expect(identical(a, b), isTrue);
      expect(resource.createCount, 1);
    });

    test('release() calls dispose and clears the instance', () async {
      final resource = _FakeFileResource();
      await resource.acquire();
      await resource.release();
      expect(resource.disposeCount, 1);
    });

    test('acquire() after release() throws StateError', () async {
      final resource = _FakeFileResource();
      await resource.acquire();
      await resource.release();
      expect(() => resource.acquire(), throwsStateError);
    });
  });
}
