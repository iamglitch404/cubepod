import 'package:cubepod_network/cubepod_network.dart';
import 'package:test/test.dart';

void main() {
  group('HttpApiClient', () {
    test('can be instantiated with a base url', () {
      final client = HttpApiClient(baseUrl: 'https://example.com');
      expect(client, isNotNull);
      client.dispose();
    });

    test('throws HttpApiException on non-2xx responses', () {
      expect(HttpApiException(404, 'Not Found').toString(),
          'HttpApiException[404]: Not Found');
    });
  });
}
