import 'package:flutter/foundation.dart';
import '../security/air_logger.dart';

/// Federated module loading for Air Framework
/// MEJORA-013: Módulos Federados
///
/// Allows loading modules from external packages dynamically.
///
/// Example:
/// ```dart
/// final loader = FederatedModuleLoader();
///
/// // Register a module factory from another package
/// loader.registerFactory(
///   'payment_module',
///   'com.example.payment',
///   () async => PaymentModule(),
/// );
///
/// // Load it when needed
/// final module = await loader.load('payment_module');
/// ```
class FederatedModuleConfig {
  /// Unique identifier for this module
  final String moduleId;

  /// Package name where the module comes from
  final String packageName;

  /// Optional version constraint
  final String? version;

  /// Optional metadata
  final Map<String, dynamic>? metadata;

  const FederatedModuleConfig({
    required this.moduleId,
    required this.packageName,
    this.version,
    this.metadata,
  });

  @override
  String toString() =>
      'FederatedModuleConfig($moduleId from $packageName${version != null ? "@$version" : ""})';
}

/// Loader for federated modules
class FederatedModuleLoader {
  static final FederatedModuleLoader _instance = FederatedModuleLoader._();
  factory FederatedModuleLoader() => _instance;
  FederatedModuleLoader._();

  final Map<String, _ModuleFactory> _factories = {};
  final Map<String, dynamic> _loadedModules = {};

  /// Register a module factory
  ///
  /// [moduleId] - Unique identifier for this module
  /// [packageName] - Package providing this module
  /// [factory] - Function that creates the module instance
  void registerFactory<T>(
    String moduleId,
    String packageName,
    Future<T> Function() factory, {
    String? version,
  }) {
    _factories[moduleId] = _ModuleFactory<T>(
      config: FederatedModuleConfig(
        moduleId: moduleId,
        packageName: packageName,
        version: version,
      ),
      factory: factory,
    );

    AirLogger.debug(
      'Registered federated module factory',
      context: {'moduleId': moduleId, 'package': packageName},
    );
  }

  /// Load a module by ID
  ///
  /// Returns the cached instance if already loaded.
  Future<T?> load<T>(String moduleId) async {
    // Check cache first
    if (_loadedModules.containsKey(moduleId)) {
      return _loadedModules[moduleId] as T?;
    }

    final factory = _factories[moduleId];
    if (factory == null) {
      AirLogger.warning(
        'No factory registered for module',
        context: {'moduleId': moduleId},
      );
      return null;
    }

    try {
      final module = await factory.factory();
      _loadedModules[moduleId] = module;

      AirLogger.debug(
        'Loaded federated module',
        context: {'moduleId': moduleId, 'package': factory.config.packageName},
      );

      return module as T?;
    } catch (e) {
      AirLogger.error(
        'Failed to load federated module',
        context: {'moduleId': moduleId},
        error: e,
      );
      return null;
    }
  }

  /// Unload a module
  void unload(String moduleId) {
    _loadedModules.remove(moduleId);
    AirLogger.debug(
      'Unloaded federated module',
      context: {'moduleId': moduleId},
    );
  }

  /// Check if a module is registered
  bool isRegistered(String moduleId) => _factories.containsKey(moduleId);

  /// Check if a module is loaded
  bool isLoaded(String moduleId) => _loadedModules.containsKey(moduleId);

  /// Get all registered module configs
  List<FederatedModuleConfig> get registeredModules =>
      _factories.values.map((f) => f.config).toList();

  /// Get all loaded module IDs
  List<String> get loadedModules => _loadedModules.keys.toList();

  /// Clear all registrations and loaded modules (for testing)
  @visibleForTesting
  void clear() {
    if (!kDebugMode) return;
    _factories.clear();
    _loadedModules.clear();
  }
}

class _ModuleFactory<T> {
  final FederatedModuleConfig config;
  final Future<T> Function() factory;

  _ModuleFactory({required this.config, required this.factory});
}
