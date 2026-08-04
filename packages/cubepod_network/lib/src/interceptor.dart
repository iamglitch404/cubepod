import 'package:http/http.dart' as http;

abstract class Interceptor {
  Future<http.Request> onRequest(http.Request request) async => request;
  Future<http.Response> onResponse(http.Response response) async => response;
  Future<dynamic> onError(dynamic error) async => error;
}

class LoggingInterceptor extends Interceptor {
  @override
  Future<http.Request> onRequest(http.Request request) async {
    // ignore: avoid_print
    print('[CubePod HTTP] --> ${request.method} ${request.url}');
    return request;
  }

  @override
  Future<http.Response> onResponse(http.Response response) async {
    // ignore: avoid_print
    print('[CubePod HTTP] <-- ${response.statusCode} ${response.request?.url}');
    return response;
  }

  @override
  Future<dynamic> onError(dynamic error) async {
    // ignore: avoid_print
    print('[CubePod HTTP] ERROR: $error');
    return error;
  }
}

class AuthInterceptor extends Interceptor {
  final Future<String?> Function() tokenProvider;

  AuthInterceptor({required this.tokenProvider});

  @override
  Future<http.Request> onRequest(http.Request request) async {
    final token = await tokenProvider();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }
}
