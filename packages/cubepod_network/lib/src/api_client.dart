abstract class ApiClient {
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters, Map<String, String>? headers});
  Future<dynamic> post(String path,
      {dynamic data, Map<String, String>? headers});
  Future<dynamic> put(String path,
      {dynamic data, Map<String, String>? headers});
  Future<dynamic> patch(String path,
      {dynamic data, Map<String, String>? headers});
  Future<dynamic> delete(String path, {Map<String, String>? headers});
}
