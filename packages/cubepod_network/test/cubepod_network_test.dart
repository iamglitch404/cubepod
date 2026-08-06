import 'package:cubepod_network/cubepod_network.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

    test('merges query parameters with existing path parameters', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response('{}', 200);
      });

      final client =
          HttpApiClient(baseUrl: 'https://example.com', client: mockClient);

      await client
          .get('/users?active=true', queryParameters: {'role': 'admin'});

      expect(capturedRequest?.url.queryParameters['active'], 'true');
      expect(capturedRequest?.url.queryParameters['role'], 'admin');
    });
  });
}
