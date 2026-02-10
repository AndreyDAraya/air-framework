import 'package:flutter/material.dart';
import '../framework/router/air_route.dart';
import '../framework/communication/event_bus.dart';

import '../framework/security/secure_service_registry.dart';
import '../framework/di/di.dart';

/// Lifecycle state of a module
enum ModuleLifecycleState {
  unloaded,
  binding,
  bound,
  initializing,
  initialized,
  disposing,
  disposed,
}

/// Base interface for all modules in the Air Framework.
///
/// Provides a complete lifecycle for modules:
/// 1. `onBind(AirDI di)` - Register dependencies (DI)
/// 2. `onInit(AirDI di)` - Async initialization logic
/// 3. `onDispose(AirDI di)` - Cleanup when module is unregistered
///
/// Example:
/// ```dart
/// class MyModule extends AppModule {
///   @override
///   String get id => 'my_module';
///
///   @override
///   String get name => 'My Module';
///
///   @override
///   void onBind(AirDI di) {
///     di.register<MyService>(MyService());
///   }
///
///   @override
///   Future<void> onInit(AirDI di) async {
///     final service = di.get<MyService>();
///     await service.loadInitialData();
///   }
///
///   @override
///   Future<void> onDispose(AirDI di) async {
///     final service = di.get<MyService>();
///     await service.cleanup();
///   }
/// }
/// ```
abstract class AppModule {
  ModuleLifecycleState _state = ModuleLifecycleState.unloaded;

  /// Current lifecycle state of the module
  ModuleLifecycleState get state => _state;

  /// Unique identifier for the module (e.g., 'auth', 'counter').
  /// Used for dependency resolution and event bus filtering.
  String get id;

  /// Human-readable name of the module (e.g., 'Authentication', 'Counter').
  /// Typically used in UI menus or debug logs.
  String get name;

  /// Version of the module following Semantic Versioning (semver).
  /// Defaults to '1.0.0'.
  String get version => '1.0.0';

  /// Icon representing the module in the application UI.
  IconData get icon => Icons.widgets;

  /// Primary color associated with the module for UI branding.
  Color get color => Colors.teal;

  /// The route path where the module starts (e.g., '/counter').
  String get initialRoute;

  /// List of [AirRoute] definitions provided by this module.
  /// All routes listed here will be registered in the global router.
  List<AirRoute> get routes;

  /// List of mandatory module dependencies.
  ///
  /// These modules will be verified during registration. If a dependency is missing,
  /// the [ModuleManager] will throw a [StateError].
  ///
  /// **Behavior:**
  /// *   Guarantees that dependencies are registered and initialized BEFORE this module.
  /// *   Supports versioning using the format `'module_id:version'`.
  /// *   If a version mismatch is found, a warning will be displayed in yellow in the console,
  ///     but it won't block the execution (unless the module is missing).
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// List<String> get dependencies => ['auth', 'notifications:^1.0.0'];
  /// ```
  List<String> get dependencies => const [];

  /// List of optional module dependencies.
  ///
  /// These modules are checked but not required for this module to function.
  /// If an optional dependency is missing, an info message will be displayed in the console.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// List<String> get optionalDependencies => ['analytics'];
  /// ```
  List<String> get optionalDependencies => const [];

  /// Synchronous configuration and dependency registration.
  ///
  /// This is the first method called in the module lifecycle. It **MUST** be strictly
  /// synchronous to ensure fast module registration.
  ///
  /// **Responsibility:** Define "how" to create dependencies (blueprints).
  /// * Register Singletons or Factories in [AirDI].
  /// * Do NOT perform asynchronous operations or heavy initialization here.
  ///
  /// If a service requires async setup (e.g., SharedPreferences, DB), register
  /// the class/service here and handle its initialization in [onInit].
  ///
  /// [di] The dependency injection container instance.
  void onBind(AirDI di) {
    _state = ModuleLifecycleState.binding;
    debugPrint('[$id] onBind');
    _state = ModuleLifecycleState.bound;
  }

  /// Asynchronous initialization logic for the module.
  ///
  /// Called after [onBind] and after all mandatory [dependencies] have been fully initialized.
  ///
  /// **Responsibility:** Perform the "heavy lifting" and preparation.
  /// * Initialize databases, local storage, or remote configurations.
  /// * Load initial state data or establish connections.
  ///
  /// This is the correct place to `await` for services registered in [onBind]
  /// to be ready before the module is marked as [ModuleLifecycleState.initialized].
  ///
  /// [di] The dependency injection container instance.
  Future<void> onInit(AirDI di) async {
    _state = ModuleLifecycleState.initializing;
    debugPrint('[$id] onInit');
    _state = ModuleLifecycleState.initialized;
  }

  /// Resource cleanup when the module is being removed.
  ///
  /// This method is called by [ModuleManager.unregister]. It handles:
  /// * Automatic cancellation of [EventBus] subscriptions for this module.
  /// * Automatic unregistration of [SecureServiceRegistry] services.
  ///
  /// **Note:** Always call `super.onDispose(di)` if you override this.
  ///
  /// [di] The dependency injection container instance.
  @mustCallSuper
  Future<void> onDispose(AirDI di) async {
    _state = ModuleLifecycleState.disposing;
    debugPrint('[$id] onDispose');

    // Clean up event subscriptions
    EventBus().cancelModuleSubscriptions(id);

    // Clean up services
    SecureServiceRegistry().unregisterModuleServices(id);

    _state = ModuleLifecycleState.disposed;
  }

  /// Global error handler for this module's lifecycle.
  ///
  /// Called whenever an error occurs during [onBind], [onInit], or [onDispose].
  ///
  /// [error] The exception or object thrown.
  /// [stackTrace] The stack trace associated with the error.
  void onError(Object error, StackTrace stackTrace) {
    debugPrint('[$id] Error: $error');
    debugPrint(stackTrace.toString());
  }
}
