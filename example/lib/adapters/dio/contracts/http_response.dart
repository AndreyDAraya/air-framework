/// A standardized HTTP response wrapper.
///
/// Abstracts away the response details from any specific HTTP library
/// so that modules only depend on this contract, not on Dio's [Response].
class HttpResponse<T> {
  /// The response body data.
  final T? data;

  /// HTTP status code (e.g., 200, 404, 500).
  final int? statusCode;

  /// HTTP status message (e.g., 'OK', 'Not Found').
  final String? statusMessage;

  /// Response headers as a map.
  final Map<String, List<String>> headers;

  const HttpResponse({
    this.data,
    this.statusCode,
    this.statusMessage,
    this.headers = const {},
  });

  /// Returns `true` if the status code is in the success range (200-299).
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  @override
  String toString() => 'HttpResponse(statusCode: $statusCode, data: $data)';
}
