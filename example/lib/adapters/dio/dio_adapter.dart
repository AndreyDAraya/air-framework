import 'package:air_framework/air_framework.dart';
import 'package:dio/dio.dart';

import 'contracts/http_client.dart';
import 'dio_http_client.dart';

/// Dio HTTP Adapter for the Air Framework.
///
/// Registers an abstract [HttpClient] in [AirDI] backed by Dio.
/// Modules should depend on [HttpClient], not on Dio directly.
///
/// ## Configuration
///
/// ```dart
/// DioAdapter(
///   baseUrl: 'https://api.example.com',
///   connectTimeout: Duration(seconds: 10),
///   receiveTimeout: Duration(seconds: 15),
///   interceptors: [LogInterceptor()],
///   headers: {'Authorization': 'Bearer tok123'},
/// )
/// ```
///
/// ## Usage from Modules
///
/// ```dart
/// class AuthModule extends AppModule {
///   @override
///   void onBind(AirDI di) {
///     di.registerLazySingleton<AuthService>(
///       () => AuthService(di.get<HttpClient>()),
///     );
///   }
/// }
/// ```
class DioAdapter extends AirAdapter {
  /// Base URL for all HTTP requests (e.g., 'https://api.example.com').
  final String baseUrl;

  /// Connection timeout duration.
  final Duration? connectTimeout;

  /// Receive timeout duration.
  final Duration? receiveTimeout;

  /// Send timeout duration.
  final Duration? sendTimeout;

  /// Additional Dio interceptors (e.g., [LogInterceptor]).
  final List<Interceptor> interceptors;

  /// Default headers to include in all requests.
  final Map<String, dynamic>? headers;

  /// Creates a [DioAdapter] with the specified configuration.
  DioAdapter({
    required this.baseUrl,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.interceptors = const [],
    this.headers,
  });

  @override
  String get id => 'dio';

  @override
  String get name => 'Dio HTTP Client';

  @override
  String get version => '1.0.0';

  @override
  void onBind(AirDI di) {
    super.onBind(di);

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: headers,
      ),
    );

    // Add user-provided interceptors
    for (final interceptor in interceptors) {
      dio.interceptors.add(interceptor);
    }

    // Register the abstract contract — modules use HttpClient, not Dio
    di.registerLazySingleton<HttpClient>(() => DioHttpClient(dio));

    // Also register the raw Dio instance for advanced use cases
    di.registerSingleton<Dio>(dio);
  }

  @override
  Future<void> onDispose(AirDI di) async {
    // Close the Dio instance to clean up resources
    final dio = di.tryGet<Dio>();
    dio?.close();
    super.onDispose(di);
  }
}
