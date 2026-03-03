import 'package:dio/dio.dart';

import 'contracts/http_client.dart';
import 'contracts/http_response.dart';

/// Dio-based implementation of the [HttpClient] contract.
///
/// This class wraps Dio's API behind the abstract [HttpClient] interface
/// so that modules never import or depend on Dio directly.
class DioHttpClient implements HttpClient {
  /// The underlying Dio instance.
  final Dio dio;

  /// Creates a [DioHttpClient] wrapping the given [dio] instance.
  DioHttpClient(this.dio);

  @override
  Future<HttpResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await dio.get(
      path,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
    );
    return _toHttpResponse(response);
  }

  @override
  Future<HttpResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
    );
    return _toHttpResponse(response);
  }

  @override
  Future<HttpResponse> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
    );
    return _toHttpResponse(response);
  }

  @override
  Future<HttpResponse> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
    );
    return _toHttpResponse(response);
  }

  @override
  Future<HttpResponse> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: headers != null ? Options(headers: headers) : null,
    );
    return _toHttpResponse(response);
  }

  /// Converts a Dio [Response] to our abstracted [HttpResponse].
  HttpResponse _toHttpResponse(Response response) {
    return HttpResponse(
      data: response.data,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      headers: response.headers.map,
    );
  }
}
