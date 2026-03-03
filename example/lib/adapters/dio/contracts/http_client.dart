import 'http_response.dart';

/// Abstract HTTP client contract for the Air Framework.
///
/// Modules should depend on this interface, **not** on Dio directly.
/// This enables swapping the HTTP implementation without touching module code.
///
/// ## Example
///
/// ```dart
/// class UserRepository {
///   final HttpClient _http;
///   UserRepository(this._http);
///
///   Future<User> getUser(int id) async {
///     final response = await _http.get('/users/$id');
///     return User.fromJson(response.data);
///   }
/// }
/// ```
abstract class HttpClient {
  /// Sends an HTTP GET request to the given [path].
  Future<HttpResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  /// Sends an HTTP POST request to the given [path].
  Future<HttpResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  /// Sends an HTTP PUT request to the given [path].
  Future<HttpResponse> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  /// Sends an HTTP PATCH request to the given [path].
  Future<HttpResponse> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  /// Sends an HTTP DELETE request to the given [path].
  Future<HttpResponse> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });
}
