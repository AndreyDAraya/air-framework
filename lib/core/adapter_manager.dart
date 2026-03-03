import 'package:flutter/material.dart';
import '../framework/di/di.dart';
import 'air_adapter.dart';

/// Manages all registered adapters in the Air Framework.
///
/// **Adapters** are infrastructure-level services (HTTP, analytics, error tracking)
/// that are registered **before** modules. This ensures that modules can safely
/// depend on adapter-provided services through [AirDI].
///
/// ## Boot Order
///
/// ```
/// Adapters (AdapterManager) → Modules (ModuleManager) → App
/// ```
///
/// ## Example
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   configureAirState();
///
///   // 1. Infrastructure adapters first
///   await AdapterManager().register(DioAdapter(baseUrl: 'https://api.example.com'));
///   await AdapterManager().register(SentryAdapter(dsn: '...'));
///
///   // 2. Feature modules second (can use adapter services)
///   await ModuleManager().register(AuthModule());
///   await ModuleManager().register(HomeModule());
///
///   runApp(const MyApp());
/// }
/// ```
class AdapterManager extends ChangeNotifier {
  static final AdapterManager _instance = AdapterManager._internal();

  /// Factory constructor to access the global instance of [AdapterManager].
  factory AdapterManager() => _instance;

  AdapterManager._internal();

  final List<AirAdapter> _adapters = [];

  /// Get all registered adapters (unmodifiable)
  List<AirAdapter> get adapters => List.unmodifiable(_adapters);

  /// Register an adapter with full lifecycle management.
  ///
  /// Lifecycle:
  /// 1. Check dependencies
  /// 2. Call `onBind(AirDI)` — synchronous service registration
  /// 3. Call `onInit(AirDI)` — async initialization
  /// 4. Add to registered adapters
  ///
  /// Throws [StateError] if a required dependency adapter is not registered.
  Future<void> register(AirAdapter adapter) async {
    if (_adapters.any((a) => a.id == adapter.id)) {
      debugPrint('AdapterManager: Adapter ${adapter.id} already registered');
      return;
    }

    // Check required dependencies
    for (final depSpec in adapter.dependencies) {
      final parts = depSpec.split(':');
      final depId = parts[0];
      final versionReq = parts.length > 1 ? parts[1] : null;

      final depAdapter = _adapters.where((a) => a.id == depId).firstOrNull;
      if (depAdapter == null) {
        throw StateError(
          'AdapterManager: Adapter "${adapter.id}" requires "$depId" '
          'but it is not registered. Register dependencies first.',
        );
      }

      // Version compatibility check
      if (versionReq != null) {
        if (!_checkVersionCompatibility(depAdapter.version, versionReq)) {
          debugPrint(
            '\x1B[33m[AdapterManager] Warning: Adapter "${adapter.id}" requires "$depId" '
            'version $versionReq, but ${depAdapter.version} is installed.\x1B[0m',
          );
        }
      }
    }

    try {
      final di = AirDI();

      // Synchronous binding
      adapter.onBind(di);

      // Async initialization
      await adapter.onInit(di);

      // Only add after successful initialization
      _adapters.add(adapter);

      debugPrint(
        'AdapterManager: Adapter ${adapter.id} v${adapter.version} registered successfully',
      );
      notifyListeners();
    } catch (e, st) {
      adapter.onError(e, st);
      debugPrint(
        'AdapterManager: Failed to initialize adapter ${adapter.id}: $e',
      );
      rethrow;
    }
  }

  /// Unregister an adapter with proper cleanup.
  ///
  /// Checks for dependents before removal.
  /// Throws [StateError] if other adapters depend on this one.
  Future<void> unregister(String adapterId) async {
    final adapter = _adapters.where((a) => a.id == adapterId).firstOrNull;
    if (adapter == null) {
      debugPrint('AdapterManager: Adapter $adapterId not found');
      return;
    }

    // Check if other adapters depend on this one
    final dependents = _adapters
        .where((a) => a.dependencies.any((d) => d.split(':')[0] == adapterId))
        .map((a) => a.id)
        .toList();

    if (dependents.isNotEmpty) {
      throw StateError(
        'AdapterManager: Cannot unregister "$adapterId". '
        'The following adapters depend on it: ${dependents.join(", ")}',
      );
    }

    try {
      await adapter.onDispose(AirDI());
    } catch (e, st) {
      adapter.onError(e, st);
    }

    _adapters.removeWhere((a) => a.id == adapterId);
    debugPrint('AdapterManager: Adapter $adapterId unregistered');
    notifyListeners();
  }

  /// Get an adapter by its ID
  AirAdapter? getAdapter(String id) {
    return _adapters.where((a) => a.id == id).firstOrNull;
  }

  /// Check if an adapter is registered
  bool isRegistered(String adapterId) =>
      _adapters.any((a) => a.id == adapterId);

  /// Check if an adapter is fully initialized
  bool isInitialized(String adapterId) {
    final adapter = getAdapter(adapterId);
    return adapter?.state == AdapterLifecycleState.initialized;
  }

  /// Returns debug info for all adapters (used by DevTools)
  List<Map<String, String>> get debugAdapterInfo => _adapters
      .map(
        (a) => {
          'id': a.id,
          'name': a.name,
          'version': a.version,
          'state': a.state.name,
        },
      )
      .toList();

  /// Clear all adapters (for testing).
  ///
  /// **Warning:** Disposes all adapters in reverse order.
  @visibleForTesting
  Future<void> reset() async {
    for (final adapter in _adapters.reversed.toList()) {
      try {
        await adapter.onDispose(AirDI());
      } catch (e) {
        debugPrint('AdapterManager: Error disposing ${adapter.id}: $e');
      }
    }
    _adapters.clear();
    notifyListeners();
  }

  /// Checks if a version satisfies a version requirement.
  /// Supports: ^1.0.0 (compatible), >=1.0.0, exact match
  bool _checkVersionCompatibility(String version, String requirement) {
    try {
      final versionParts = _parseVersion(version);

      if (requirement.startsWith('^')) {
        final reqParts = _parseVersion(requirement.substring(1));
        if (!_isGreaterOrEqual(versionParts, reqParts)) return false;
        final nextMajor = [reqParts[0] + 1, 0, 0];
        if (!_isLessThan(versionParts, nextMajor)) return false;
        return true;
      }

      if (requirement.startsWith('>=')) {
        final reqParts = _parseVersion(requirement.substring(2));
        return _isGreaterOrEqual(versionParts, reqParts);
      }

      // Exact match
      final reqParts = _parseVersion(requirement);
      return versionParts[0] == reqParts[0] &&
          versionParts[1] == reqParts[1] &&
          versionParts[2] == reqParts[2];
    } catch (e) {
      debugPrint('AdapterManager: Version check failed: $e');
      return true;
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
    return true;
  }

  bool _isLessThan(List<int> a, List<int> b) => !_isGreaterOrEqual(a, b);
}
