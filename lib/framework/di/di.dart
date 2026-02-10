import 'package:flutter/foundation.dart';
import '../security/air_logger.dart';
import '../security/air_audit.dart';

/// Exception thrown when a dependency [type] is requested but not found in the [AirDI] container.
///
/// Typical cause: Forgetting to register the dependency in the module's `onBind` method.
class DependencyNotFoundException implements Exception {
  /// The type of the missing dependency.
  final Type type;

  DependencyNotFoundException(this.type);

  @override
  String toString() =>
      'DependencyNotFoundException: ${type.toString()} not registered. '
      'Did you forget to call di.register<${type.toString()}>(...)  in onBind(AirDI di)?';
}

/// Exception thrown when attempting to register a dependency [type] that is already registered.
///
/// This protects against accidental overwrites of existing services.
/// To explicitly allow overwriting, set `allowOverwrite: true` during registration.
class DependencyAlreadyRegisteredException implements Exception {
  /// The type of the dependency that already exists.
  final Type type;

  DependencyAlreadyRegisteredException(this.type);

  @override
  String toString() =>
      'DependencyAlreadyRegisteredException: ${type.toString()} is already registered. '
      'Use allowOverwrite: true to replace existing registrations.';
}

/// A centralized Service Locator for the Air Framework.
///
/// Features:
/// * **Overwrite Protection:** Prevents accidental overwriting of services by default.
/// * **Audit Logging:** Logs all registration attempts and access violations.
/// * **Ownership Tracking:** Keeps track of which module registered each dependency.
/// * **Module Cleanup:** Allows unregistering all dependencies of a specific module during its disposal.
class AirDI {
  static final AirDI _instance = AirDI._internal();

  /// Factory constructor to access the global instance of [AirDI].
  factory AirDI() => _instance;

  AirDI._internal();

  /// Internal map of registered dependencies and their storage wrappers.
  final Map<Type, _Dependency> _registrations = {};

  /// Tracks which module ID owns each registered dependency type.
  final Map<Type, String?> _registrationOwners = {};

  /// Returns a list of all registered types as strings for debugging/DevTools purposes.
  List<String> get debugRegisteredTypes =>
      _registrations.keys.map((t) => t.toString()).toList();

  /// Returns a map of registered types and their owner modules for debugging/DevTools purposes.
  Map<String, String?> get debugRegistrationInfo => Map.fromEntries(
    _registrations.keys.map(
      (t) => MapEntry(t.toString(), _registrationOwners[t]),
    ),
  );

  /// Registers a dependency as a Singleton.
  ///
  /// This is an alias for [registerSingleton].
  ///
  /// [instance] The object instance to store.
  /// [moduleId] Optional ID of the module that owns this registration.
  /// [allowOverwrite] If true, allows replacing an existing registration of the same type.
  void register<T>(
    T instance, {
    String? moduleId,
    bool allowOverwrite = false,
  }) => registerSingleton<T>(
    instance,
    moduleId: moduleId,
    allowOverwrite: allowOverwrite,
  );

  /// Registers a dependency as a Singleton (Immediate).
  ///
  /// If the type is already registered and [allowOverwrite] is false,
  /// it will throw [DependencyAlreadyRegisteredException].
  ///
  /// [instance] The object instance to store.
  /// [moduleId] Optional ID of the module that owns this registration.
  /// [allowOverwrite] Set to true to replace existing dependencies (useful for testing/mocking).
  void registerSingleton<T>(
    T instance, {
    String? moduleId,
    bool allowOverwrite = false,
  }) {
    // Prevent accidental overwrites
    if (_registrations.containsKey(T) && !allowOverwrite) {
      AirLogger.warning(
        'Dependency already registered',
        context: {
          'type': T.toString(),
          'existingOwner': _registrationOwners[T],
          'newOwner': moduleId,
        },
      );
      AirAudit().log(
        type: AuditType.securityViolation,
        action: 'dependency_overwrite_blocked',
        moduleId: moduleId ?? 'unknown',
        context: {
          'type': T.toString(),
          'existingOwner': _registrationOwners[T],
        },
        severity: AuditSeverity.medium,
        success: false,
      );
      throw DependencyAlreadyRegisteredException(T);
    }

    _registrations[T] = _SingletonDependency<T>(instance);
    _registrationOwners[T] = moduleId;

    AirLogger.debug(
      'Registered Singleton',
      context: {'type': T.toString(), 'module': moduleId},
    );
  }

  /// Registers a Lazy Singleton.
  ///
  /// The [factory] function will only be executed the first time the dependency is requested.
  ///
  /// [factory] A function that creates the instance.
  /// [moduleId] Optional ID of the module that owns this registration.
  /// [allowOverwrite] If true, allows replacing an existing registration.
  void registerLazySingleton<T>(
    T Function() factory, {
    String? moduleId,
    bool allowOverwrite = false,
  }) {
    if (_registrations.containsKey(T) && !allowOverwrite) {
      AirLogger.warning(
        'Dependency already registered',
        context: {'type': T.toString()},
      );
      throw DependencyAlreadyRegisteredException(T);
    }

    _registrations[T] = _LazySingletonDependency<T>(factory);
    _registrationOwners[T] = moduleId;

    AirLogger.debug(
      'Registered LazySingleton',
      context: {'type': T.toString(), 'module': moduleId},
    );
  }

  /// Registers a Factory.
  ///
  /// A new instance is created every time [get] is called by executing the [factory] function.
  ///
  /// [factory] A function that creates a new instance cada vez que se solicita.
  /// [moduleId] Optional ID of the module that owns this registration.
  /// [allowOverwrite] If true, allows replacing an existing registration.
  void registerFactory<T>(
    T Function() factory, {
    String? moduleId,
    bool allowOverwrite = false,
  }) {
    if (_registrations.containsKey(T) && !allowOverwrite) {
      AirLogger.warning(
        'Dependency already registered',
        context: {'type': T.toString()},
      );
      throw DependencyAlreadyRegisteredException(T);
    }

    _registrations[T] = _FactoryDependency<T>(factory);
    _registrationOwners[T] = moduleId;

    AirLogger.debug(
      'Registered Factory',
      context: {'type': T.toString(), 'module': moduleId},
    );
  }

  /// Retrieves a registered dependency of type [T].
  ///
  /// Throws [DependencyNotFoundException] if the type is not registered.
  T get<T>() {
    final dependency = _registrations[T];
    if (dependency == null) {
      throw DependencyNotFoundException(T);
    }
    return dependency.get() as T;
  }

  /// Tries to retrieve a registered dependency of type [T].
  ///
  /// Returns `null` if the dependency is not found instead of throwing an exception.
  T? tryGet<T>() {
    final dependency = _registrations[T];
    return dependency?.get() as T?;
  }

  /// Returns `true` if a dependency of type [T] is currently registered.
  bool isRegistered<T>() => _registrations.containsKey(T);

  /// Returns the ID of the module that registered the dependency of type [T].
  ///
  /// Returns `null` if the dependency was registered without a module ID or is not found.
  String? getOwner<T>() => _registrationOwners[T];

  /// Unregisters a dependency of type [T].
  ///
  /// If ownership tracking is enabled, [callerModuleId] must match the original owner
  /// to perform the unregistration. Returns `true` on success.
  ///
  /// [callerModuleId] Optional ID of the module attempting to unregister the service.
  bool unregister<T>({String? callerModuleId}) {
    final owner = _registrationOwners[T];

    // Ownership check: Verify that only the owner can unregister
    if (owner != null && callerModuleId != null && owner != callerModuleId) {
      AirLogger.warning(
        'Unauthorized unregister attempt',
        context: {
          'type': T.toString(),
          'owner': owner,
          'caller': callerModuleId,
        },
      );
      AirAudit().log(
        type: AuditType.securityViolation,
        action: 'unauthorized_unregister',
        moduleId: callerModuleId,
        context: {'type': T.toString(), 'owner': owner},
        severity: AuditSeverity.medium,
        success: false,
      );
      return false;
    }

    _registrations.remove(T);
    _registrationOwners.remove(T);
    AirLogger.debug('Unregistered', context: {'type': T.toString()});
    return true;
  }

  /// Unregisters all dependencies that belong to a specific [moduleId].
  ///
  /// This is used internally during module disposal to clean up system resources.
  void unregisterModule(String moduleId) {
    final typesToRemove = _registrationOwners.entries
        .where((e) => e.value == moduleId)
        .map((e) => e.key)
        .toList();

    for (final type in typesToRemove) {
      _registrations.remove(type);
      _registrationOwners.remove(type);
    }

    if (typesToRemove.isNotEmpty) {
      AirLogger.debug(
        'Unregistered module dependencies',
        context: {'module': moduleId, 'count': typesToRemove.length},
      );
    }
  }

  /// Clears all registrations in the container.
  ///
  /// **Warning:** This method only works in debug mode (`kDebugMode`).
  /// It is ignored in release mode to prevent accidental service loss.
  @visibleForTesting
  void clear() {
    if (!kDebugMode) {
      AirLogger.warning('AirDI.clear() called in release mode - ignored');
      return;
    }
    _registrations.clear();
    _registrationOwners.clear();
  }
}

/// Internal wrapper for dependency storage.
abstract class _Dependency<T> {
  /// Returns the instance or creates it via a factory.
  T get();
}

/// Wrapper for direct Singleton instances.
class _SingletonDependency<T> implements _Dependency<T> {
  final T _instance;
  _SingletonDependency(this._instance);
  @override
  T get() => _instance;
}

/// Wrapper for Lazy Singletons that initializes on the first [get] call.
class _LazySingletonDependency<T> implements _Dependency<T> {
  final T Function() _factory;
  T? _instance;
  _LazySingletonDependency(this._factory);
  @override
  T get() => _instance ??= _factory();
}

/// Wrapper for Factory registrations that creates a new instance every time.
class _FactoryDependency<T> implements _Dependency<T> {
  final T Function() _factory;
  _FactoryDependency(this._factory);
  @override
  T get() => _factory();
}
