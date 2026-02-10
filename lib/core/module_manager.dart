import 'package:flutter/material.dart';
import '../framework/router/air_route.dart';
import '../framework/communication/event_bus.dart';
import '../framework/communication/module_context.dart';
import '../framework/di/di.dart';
import 'app_module.dart';

/// Manages all registered modules in the Air Framework.
///
/// Provides:
/// - Module registration with lifecycle management
/// - Dependency resolution
/// - Route aggregation
/// - Module context access
///
/// Example:
/// ```dart
/// await ModuleManager().register(HomeModule());
/// await ModuleManager().register(SettingsModule());
///
/// // Access module context
/// final context = ModuleManager().getContext('home');
/// ```
class ModuleManager extends ChangeNotifier {
  static final ModuleManager _instance = ModuleManager._internal();
  factory ModuleManager() => _instance;
  ModuleManager._internal();

  final List<AppModule> _modules = [];
  final Map<String, ModuleContext> _contexts = {};

  /// Get all registered modules
  List<AppModule> get modules => List.unmodifiable(_modules);

  /// Register a module with full lifecycle management
  ///
  /// Lifecycle:
  /// 1. Check dependencies
  /// 2. Call onBind(AirDI)
  /// 3. Call onInit(AirDI)
  /// 4. Add to registered modules
  Future<void> register(AppModule module) async {
    if (_modules.any((m) => m.id == module.id)) {
      debugPrint('ModuleManager: Module ${module.id} already registered');
      return;
    }

    // Check required dependencies (with version if specified)
    for (final depSpec in module.dependencies) {
      // Parse dependency specification (e.g., "auth:^1.0.0" or just "auth")
      final parts = depSpec.split(':');
      final depId = parts[0];
      final versionReq = parts.length > 1 ? parts[1] : null;

      final depModule = _modules.where((m) => m.id == depId).firstOrNull;
      if (depModule == null) {
        throw StateError(
          'ModuleManager: Module "${module.id}" requires "$depId" '
          'but it is not registered. Register dependencies first.',
        );
      }

      // Verify version compatibility if version requirement is specified
      if (versionReq != null) {
        if (!_checkVersionCompatibility(depModule.version, versionReq)) {
          debugPrint(
            '\x1B[33m[ModuleManager] Warning: Module "${module.id}" requires "$depId" '
            'version $versionReq, but ${depModule.version} is installed.\x1B[0m',
          );
        }
      }
    }

    // Log optional dependencies that are missing
    for (final depSpec in module.optionalDependencies) {
      final parts = depSpec.split(':');
      final depId = parts[0];
      if (!_modules.any((m) => m.id == depId)) {
        debugPrint(
          '\x1B[33m[ModuleManager] Info: Optional dependency "$depId" for "${module.id}" '
          'is not available.\x1B[0m',
        );
      }
    }

    // Create context for the module
    final context = ModuleContext(moduleId: module.id, moduleName: module.name);

    try {
      // Get DI instance
      final di = AirDI();

      // Register dependencies before initialization
      module.onBind(di);

      // Self-initialization without main.dart knowing details
      await module.onInit(di);

      // Only add to modules list AFTER successful initialization
      _modules.add(module);
      _contexts[module.id] = context;

      // Emit module installed event
      EventBus().emit(
        ModuleInstalledEvent(
          sourceModuleId: 'system',
          installedModuleId: module.id,
          installedModuleName: module.name,
          version: module.version,
        ),
      );

      debugPrint('ModuleManager: Module ${module.id} registered successfully');
      notifyListeners();
    } catch (e, st) {
      module.onError(e, st);
      debugPrint('ModuleManager: Failed to initialize module ${module.id}: $e');
      rethrow;
    }
  }

  /// Unregister a module with proper cleanup
  Future<void> unregister(String moduleId) async {
    final module = _modules.firstWhereOrNull((m) => m.id == moduleId);
    if (module == null) {
      debugPrint('ModuleManager: Module $moduleId not found');
      return;
    }

    // Check if other modules depend on this one
    final dependents = _modules
        .where((m) => m.dependencies.contains(moduleId))
        .map((m) => m.id)
        .toList();

    if (dependents.isNotEmpty) {
      throw StateError(
        'ModuleManager: Cannot unregister "$moduleId". '
        'The following modules depend on it: ${dependents.join(", ")}',
      );
    }

    try {
      await module.onDispose(AirDI());
    } catch (e, st) {
      module.onError(e, st);
    }

    _modules.removeWhere((m) => m.id == moduleId);
    _contexts.remove(moduleId);

    // Emit module uninstalled event
    EventBus().emit(
      ModuleUninstalledEvent(
        sourceModuleId: 'system',
        uninstalledModuleId: moduleId,
      ),
    );

    debugPrint('ModuleManager: Module $moduleId unregistered');
    notifyListeners();
  }

  /// Get all routes from all modules (AirRoute)
  /// Warns if duplicate routes are found
  List<AirRoute> getAirRoutes() {
    final allRoutes = <AirRoute>[];
    final seenPaths = <String, String>{}; // path -> moduleId

    for (final module in _modules) {
      for (final route in module.routes) {
        _checkDuplicateRoutes(route, module.id, seenPaths);
      }
      allRoutes.addAll(module.routes);
    }
    return allRoutes;
  }

  /// Recursively check for duplicate route paths
  void _checkDuplicateRoutes(
    AirRoute route,
    String moduleId,
    Map<String, String> seenPaths,
  ) {
    if (seenPaths.containsKey(route.path)) {
      debugPrint(
        '\x1B[33m[ModuleManager] Warning: Route "${route.path}" is defined by both '
        '"${seenPaths[route.path]}" and "$moduleId". '
        'This may cause unexpected routing behavior.\x1B[0m',
      );
    } else {
      seenPaths[route.path] = moduleId;
    }

    // Check child routes recursively
    for (final childRoute in route.routes) {
      _checkDuplicateRoutes(childRoute, moduleId, seenPaths);
    }
  }

  /// Get a module by ID
  AppModule? getModule(String id) {
    return _modules.firstWhereOrNull((m) => m.id == id);
  }

  /// Get module context by ID
  ModuleContext? getContext(String moduleId) => _contexts[moduleId];

  /// Check if a module is registered
  bool isRegistered(String moduleId) => _modules.any((m) => m.id == moduleId);

  /// Check if a module is fully initialized
  bool isInitialized(String moduleId) {
    final module = getModule(moduleId);
    return module?.state == ModuleLifecycleState.initialized;
  }

  /// Clear all modules (for testing)
  @visibleForTesting
  Future<void> reset() async {
    // Dispose all modules in reverse order
    for (final module in _modules.reversed.toList()) {
      try {
        await module.onDispose(AirDI());
      } catch (e) {
        debugPrint('ModuleManager: Error disposing ${module.id}: $e');
      }
    }
    _modules.clear();
    _contexts.clear();
    notifyListeners();
  }

  /// Checks if a version satisfies a version requirement.
  /// Supports: ^1.0.0 (compatible), >=1.0.0, >1.0.0, <=1.0.0, <1.0.0, 1.0.0 (exact)
  bool _checkVersionCompatibility(String version, String requirement) {
    try {
      final versionParts = _parseVersion(version);

      // Handle caret syntax (^1.0.0 = >=1.0.0 <2.0.0)
      if (requirement.startsWith('^')) {
        final reqParts = _parseVersion(requirement.substring(1));
        // Must be >= required version
        if (!_isGreaterOrEqual(versionParts, reqParts)) return false;
        // Must be < next major version
        final nextMajor = [reqParts[0] + 1, 0, 0];
        if (!_isLessThan(versionParts, nextMajor)) return false;
        return true;
      }

      // Handle >= syntax
      if (requirement.startsWith('>=')) {
        final reqParts = _parseVersion(requirement.substring(2));
        return _isGreaterOrEqual(versionParts, reqParts);
      }

      // Handle > syntax
      if (requirement.startsWith('>') && !requirement.startsWith('>=')) {
        final reqParts = _parseVersion(requirement.substring(1));
        return _isGreaterThan(versionParts, reqParts);
      }

      // Handle <= syntax
      if (requirement.startsWith('<=')) {
        final reqParts = _parseVersion(requirement.substring(2));
        return _isLessOrEqual(versionParts, reqParts);
      }

      // Handle < syntax
      if (requirement.startsWith('<') && !requirement.startsWith('<=')) {
        final reqParts = _parseVersion(requirement.substring(1));
        return _isLessThan(versionParts, reqParts);
      }

      // Exact match
      final reqParts = _parseVersion(requirement);
      return versionParts[0] == reqParts[0] &&
          versionParts[1] == reqParts[1] &&
          versionParts[2] == reqParts[2];
    } catch (e) {
      debugPrint('ModuleManager: Version check failed: $e');
      return true; // Be permissive on parse errors
    }
  }

  List<int> _parseVersion(String version) {
    final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.take(3).toList();
  }

  bool _isGreaterOrEqual(List<int> a, List<int> b) {
    for (int i = 0; i < 3; i++) {
      if (a[i] > b[i]) return true;
      if (a[i] < b[i]) return false;
    }
    return true; // Equal
  }

  bool _isGreaterThan(List<int> a, List<int> b) {
    for (int i = 0; i < 3; i++) {
      if (a[i] > b[i]) return true;
      if (a[i] < b[i]) return false;
    }
    return false; // Equal
  }

  bool _isLessOrEqual(List<int> a, List<int> b) => !_isGreaterThan(a, b);
  bool _isLessThan(List<int> a, List<int> b) => !_isGreaterOrEqual(a, b);
}

/// Extension to add firstWhereOrNull to List
extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
