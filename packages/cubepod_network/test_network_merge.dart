import 'package:cubepod_network/cubepod_network.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('HttpApiClient merges query parameters', () async {
    http.Request? capturedRequest;
    final mockClient = MockClient((request) async {
      capturedRequest = request;
      return http.Response('{}', 200);
    });

    final client =
        HttpApiClient(baseUrl: 'https://example.com', client: mockClient);

    await client.get('/users?active=true', queryParameters: {'role': 'admin'});

    // Check if the query parameter 'active=true' is preserved.
    expect(capturedRequest?.url.queryParameters['active'], 'true');
    expect(capturedRequest?.url.queryParameters['role'], 'admin');
  });
}
