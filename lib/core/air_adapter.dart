import 'package:flutter/material.dart';
import '../framework/di/di.dart';

/// Lifecycle state of an adapter
enum AdapterLifecycleState {
  unloaded,
  binding,
  bound,
  initializing,
  initialized,
  disposing,
  disposed,
}

/// Base interface for all Adapters in the Air Framework.
///
/// An **Adapter** encapsulates an external integration (HTTP client, error tracking,
/// analytics, local storage, etc.) without the overhead of a full [AppModule].
///
/// Unlike modules, adapters do **not** have routes, UI (icon/color), or navigation.
/// They focus exclusively on registering and managing **infrastructure services**.
///
/// Adapters are registered **before** modules so that modules can depend on
/// adapter-provided services through the shared [AirDI] container.
///
/// ## Lifecycle
///
/// 1. `onBind(AirDI di)` — Register dependencies synchronously
/// 2. `onInit(AirDI di)` — Async initialization (connections, configs)
/// 3. `onDispose(AirDI di)` — Cleanup resources
///
/// ## Example
///
/// ```dart
/// class DioAdapter extends AirAdapter {
///   final String baseUrl;
///   DioAdapter({required this.baseUrl});
///
///   @override
///   String get id => 'dio';
///
///   @override
///   String get name => 'Dio HTTP Client';
///
///   @override
///   void onBind(AirDI di) {
///     di.registerLazySingleton<HttpClient>(() => DioHttpClient(baseUrl));
///   }
/// }
/// ```
///
/// ## Community Publishing Convention
///
/// Adapter packages should follow the naming pattern: `air_adapter_<service>`
///
/// | Package                | Description            |
/// |------------------------|------------------------|
/// | `air_adapter_dio`      | HTTP client with Dio   |
/// | `air_adapter_sentry`   | Error tracking         |
/// | `air_adapter_firebase` | Firebase integration   |
/// | `air_adapter_hive`     | Local storage          |
abstract class AirAdapter {
  AdapterLifecycleState _state = AdapterLifecycleState.unloaded;

  /// Current lifecycle state of the adapter
  AdapterLifecycleState get state => _state;

  /// Unique identifier for the adapter (e.g., 'dio', 'sentry').
  /// Used for dependency resolution and debugging.
  String get id;

  /// Human-readable name of the adapter (e.g., 'Dio HTTP Client').
  /// Used in DevTools and debug logs.
  String get name;

  /// Version of the adapter following Semantic Versioning (semver).
  /// Defaults to '1.0.0'.
  String get version => '1.0.0';

  /// List of other adapter IDs that this adapter depends on.
  ///
  /// These adapters will be verified during registration. If a dependency is missing,
  /// the [AdapterManager] will throw a [StateError].
  ///
  /// Supports versioning using the format `'adapter_id:version'`.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<String> get dependencies => ['sentry:^1.0.0'];
  /// ```
  List<String> get dependencies => const [];

  /// Synchronous configuration and dependency registration.
  ///
  /// This is the first method called in the adapter lifecycle. It **MUST** be
  /// strictly synchronous to ensure fast adapter registration.
  ///
  /// **Responsibility:** Register services, factories, and singletons in [AirDI].
  ///
  /// [di] The dependency injection container instance.
  void onBind(AirDI di) {
    _state = AdapterLifecycleState.binding;
    debugPrint('[Adapter:$id] onBind');
    _state = AdapterLifecycleState.bound;
  }

  /// Asynchronous initialization logic for the adapter.
  ///
  /// Called after [onBind]. Use this for heavy setup like establishing connections,
  /// loading configurations, or initializing SDKs.
  ///
  /// [di] The dependency injection container instance.
  Future<void> onInit(AirDI di) async {
    _state = AdapterLifecycleState.initializing;
    debugPrint('[Adapter:$id] onInit');
    _state = AdapterLifecycleState.initialized;
  }

  /// Resource cleanup when the adapter is being removed.
  ///
  /// Use this to close connections, flush buffers, or release resources.
  ///
  /// [di] The dependency injection container instance.
  @mustCallSuper
  Future<void> onDispose(AirDI di) async {
    _state = AdapterLifecycleState.disposing;
    debugPrint('[Adapter:$id] onDispose');
    _state = AdapterLifecycleState.disposed;
  }

  /// Global error handler for this adapter's lifecycle.
  ///
  /// Called whenever an error occurs during [onBind], [onInit], or [onDispose].
  ///
  /// [error] The exception or object thrown.
  /// [stackTrace] The stack trace associated with the error.
  void onError(Object error, StackTrace stackTrace) {
    debugPrint('[Adapter:$id] Error: $error');
    debugPrint(stackTrace.toString());
  }
}
