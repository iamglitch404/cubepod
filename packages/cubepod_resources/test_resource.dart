import 'package:cubepod_resources/cubepod_resources.dart';

class TestResource extends Resource<String> {
  int createCount = 0;

  @override
  Future<String> create() async {
    createCount++;
    await Future.delayed(const Duration(milliseconds: 50));
    return 'instance_$createCount';
  }

  @override
  Future<void> dispose(String instance) async {}
}

void main() async {
  final res = TestResource();
  // Call acquire concurrently
  final future1 = res.acquire();
  final future2 = res.acquire();

  final val1 = await future1;
  final val2 = await future2;

  print("createCount: ${res.createCount}");
  print("val1: $val1, val2: $val2");
  if (res.createCount != 1) {
    throw Exception(
      "Resource created multiple times! createCount=${res.createCount}",
    );
  }
}
