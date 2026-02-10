import '../security/secure_service_registry.dart';
import '../security/identity.dart';
import 'event_bus.dart';

/// Context provided to modules during lifecycle.
/// Provides convenient access to framework services with automatic module ID tracking.
///
/// Example:
/// ```dart
/// // In your module
/// final context = ModuleManager().getContext('my_module');
/// context?.registerService(
///   name: 'my_service',
///   service: () => MyService(),
/// );
/// ```
class ModuleContext {
  final String moduleId;
  final String moduleName;
  final SecureServiceRegistry services;
  final EventBus eventBus;

  /// The identity token issued by the framework to verify this module.
  /// Used for secure inter-module communication.
  final ModuleIdentityToken? identityToken;

  ModuleContext({
    required this.moduleId,
    required this.moduleName,
    this.identityToken,
    SecureServiceRegistry? services,
    EventBus? eventBus,
  }) : services = services ?? SecureServiceRegistry(),
       eventBus = eventBus ?? EventBus();

  /// Get a service by name
  T? getService<T>(String serviceName) {
    return services.getService<T>(serviceName, callerModuleId: moduleId);
  }

  /// Register a service with this module as owner
  void registerService({
    required String name,
    required Function service,
    List<String> allowedCallers = const [],
  }) {
    services.registerService(
      name: name,
      ownerModuleId: moduleId,
      service: service,
      allowedCallers: allowedCallers,
    );
  }

  /// Emit a typed event
  void emit<T extends ModuleEvent>(T event) {
    eventBus.emit(event);
  }

  /// Subscribe to a typed event
  EventSubscription on<T extends ModuleEvent>(void Function(T event) callback) {
    return eventBus.on<T>(callback, subscriberModuleId: moduleId);
  }

  /// Emit a named signal with identity verification.
  /// Automatically includes the [identityToken] to allow the receiver to verify
  /// that the signal truly originated from this module.
  void emitSignal(String signalName, {dynamic data}) {
    eventBus.emitSignal(
      signalName,
      data: data,
      sourceModuleId: moduleId,
      identityToken: identityToken,
    );
  }

  /// Set shared data with optional encryption and time-to-live (TTL).
  ///
  /// This provides a secure way to share data between modules with built-in
  /// protection and automatic expiration.
  void setSecureData<T>(
    String key,
    T value, {
    bool encrypt = false,
    Duration? ttl,
  }) {
    services.setSecureData<T>(
      key,
      value,
      callerModuleId: moduleId,
      encrypt: encrypt,
      ttl: ttl,
    );
  }

  /// Retrieve shared data while handling secure metadata and access control.
  T? getSecureData<T>(String key) {
    return services.getSecureData<T>(key, callerModuleId: moduleId);
  }

  /// Subscribe to a named signal
  EventSubscription onSignal(
    String signalName,
    void Function(dynamic data) callback,
  ) {
    return eventBus.onSignal(
      signalName,
      callback,
      subscriberModuleId: moduleId,
    );
  }
}
