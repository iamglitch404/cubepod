import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cubepod_core/cubepod_core.dart';
import 'api_client.dart';
import 'interceptor.dart';

class HttpApiClient implements ApiClient, Disposable {
  final String baseUrl;
  final List<Interceptor> interceptors;
  final http.Client _client;
  final Duration? timeout;

  HttpApiClient({
    required this.baseUrl,
    this.interceptors = const [],
    this.timeout,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<http.Request> _runRequestInterceptors(http.Request request) async {
    http.Request current = request;
    for (final interceptor in interceptors) {
      current = await interceptor.onRequest(current);
    }
    return current;
  }

  Future<http.Response> _runResponseInterceptors(http.Response response) async {
    http.Response current = response;
    for (final interceptor in interceptors) {
      current = await interceptor.onResponse(current);
    }
    return current;
  }

  Future<dynamic> _runErrorInterceptors(dynamic error) async {
    dynamic current = error;
    for (final interceptor in interceptors) {
      current = await interceptor.onError(current);
    }
    return current;
  }

  Future<http.Response> _send(http.Request request) async {
    final intercepted = await _runRequestInterceptors(request);
    final streamedResponse = timeout != null
        ? await _client.send(intercepted).timeout(timeout!)
        : await _client.send(intercepted);
    return http.Response.fromStream(streamedResponse);
  }

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters,
      Map<String, String>? headers}) async {
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParameters != null) {
        uri = uri.replace(
            queryParameters:
                queryParameters.map((k, v) => MapEntry(k, v.toString())));
      }
      final request = http.Request('GET', uri);
      if (headers != null) request.headers.addAll(headers);
      var response = await _send(request);
      response = await _runResponseInterceptors(response);
      return _parseResponse(response);
    } catch (e) {
      throw await _runErrorInterceptors(e);
    }
  }

  @override
  Future<dynamic> post(String path,
      {dynamic data, Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.Request('POST', uri);
      if (data != null) {
        request.body = jsonEncode(data);
        request.headers['Content-Type'] = 'application/json';
      }
      if (headers != null) request.headers.addAll(headers);
      var response = await _send(request);
      response = await _runResponseInterceptors(response);
      return _parseResponse(response);
    } catch (e) {
      throw await _runErrorInterceptors(e);
    }
  }

  @override
  Future<dynamic> put(String path,
      {dynamic data, Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.Request('PUT', uri);
      if (data != null) {
        request.body = jsonEncode(data);
        request.headers['Content-Type'] = 'application/json';
      }
      if (headers != null) request.headers.addAll(headers);
      var response = await _send(request);
      response = await _runResponseInterceptors(response);
      return _parseResponse(response);
    } catch (e) {
      throw await _runErrorInterceptors(e);
    }
  }

  @override
  Future<dynamic> patch(String path,
      {dynamic data, Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.Request('PATCH', uri);
      if (data != null) {
        request.body = jsonEncode(data);
        request.headers['Content-Type'] = 'application/json';
      }
      if (headers != null) request.headers.addAll(headers);
      var response = await _send(request);
      response = await _runResponseInterceptors(response);
      return _parseResponse(response);
    } catch (e) {
      throw await _runErrorInterceptors(e);
    }
  }

  @override
  Future<dynamic> delete(String path, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.Request('DELETE', uri);
      if (headers != null) request.headers.addAll(headers);
      var response = await _send(request);
      response = await _runResponseInterceptors(response);
      return _parseResponse(response);
    } catch (e) {
      throw await _runErrorInterceptors(e);
    }
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      throw HttpApiException(response.statusCode, response.body);
    }
  }

  @override
  void dispose() {
    _client.close();
  }
}

class HttpApiException implements Exception {
  final int statusCode;
  final String body;
  HttpApiException(this.statusCode, this.body);

  @override
  String toString() => 'HttpApiException[$statusCode]: $body';
}
