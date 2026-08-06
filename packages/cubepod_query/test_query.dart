import 'package:cubepod_query/cubepod_query.dart';

void main() async {
  final query = CubeQuery<String>(
    queryFn: () async {
      await Future.delayed(const Duration(milliseconds: 100));
      return 'data';
    },
  );

  // First fetch starts loading

  // Second fetch happens immediately after, while still loading
  final f2 = query.fetch();

  // Await the second fetch. If it correctly returns the active future,
  // data should be 'data' after this await.
  await f2;

  if (query.value.data != 'data') {
    throw Exception(
        "Bug reproduced! f2 completed, but data is still ${query.value.data} (expected 'data')");
  }
}
