import 'dart:async';
import 'package:flutter/foundation.dart';
import '../state/air.dart';
import '../security/air_logger.dart';

/// Hot Module Reload (HMR) support for development.
///
/// This utility allows reloading individual modules during development without
/// a full application restart, while optionally preserving their reactive state.
///
/// Example:
/// ```dart
/// await AirHotReload().hotReload(
///   'my_module',
///   onBeforeReload: () async {
///     // Save any pending state
///   },
///   onAfterReload: () async {
///     // Reinitialize subscriptions
///   },
/// );
/// ```
class AirHotReload {
  static final AirHotReload _instance = AirHotReload._();
  factory AirHotReload() => _instance;
  AirHotReload._();

  /// Track module state for reload
  final Map<String, Map<String, dynamic>> _preservedState = {};

  /// Track reload listeners
  final Map<String, List<VoidCallback>> _reloadListeners = {};

  /// Check if HMR is available (only in debug mode)
  bool get isAvailable => kDebugMode;

  /// Preserve state before module reload
  ///
  /// Call this before disposing a module to save its state for restoration.
  void preserveState(String moduleId, Map<String, dynamic> state) {
    if (!kDebugMode) return;
    _preservedState[moduleId] = Map.from(state);
    AirLogger.debug(
      'Preserved state for HMR',
      context: {'moduleId': moduleId, 'keys': state.keys.toList()},
    );
  }

  /// Restore preserved state after module reload
  ///
  /// Returns the preserved state or null if not available.
  Map<String, dynamic>? restoreState(String moduleId) {
    if (!kDebugMode) return null;
    final state = _preservedState.remove(moduleId);
    if (state != null) {
      AirLogger.debug(
        'Restored state from HMR',
        context: {'moduleId': moduleId, 'keys': state.keys.toList()},
      );
    }
    return state;
  }

  /// Check if there's preserved state for a module
  bool hasPreservedState(String moduleId) {
    return _preservedState.containsKey(moduleId);
  }

  /// Hot reload a module while preserving its state
  ///
  /// This method:
  /// 1. Captures the current module state
  /// 2. Calls onBeforeReload (dispose old module)
  /// 3. Calls onAfterReload (initialize new module)
  /// 4. Restores the captured state
  Future<void> hotReload(
    String moduleId, {
    Future<void> Function()? onBeforeReload,
    Future<void> Function()? onAfterReload,
    List<String>? stateKeysToPreserve,
  }) async {
    if (!kDebugMode) {
      AirLogger.warning('HMR is only available in debug mode');
      return;
    }

    AirLogger.info('Starting hot reload', context: {'moduleId': moduleId});

    try {
      // 1. Capture state to preserve
      if (stateKeysToPreserve != null && stateKeysToPreserve.isNotEmpty) {
        final stateToPreserve = <String, dynamic>{};
        for (final key in stateKeysToPreserve) {
          final controller = Air().debugStates[key];
          if (controller != null) {
            stateToPreserve[key] = controller.value;
          }
        }
        preserveState(moduleId, stateToPreserve);
      }

      // 2. Notify listeners before reload
      _notifyListeners(moduleId);

      // 3. Dispose old module
      if (onBeforeReload != null) {
        await onBeforeReload();
      }

      // 4. Initialize new module
      if (onAfterReload != null) {
        await onAfterReload();
      }

      // 5. Restore state
      final preserved = restoreState(moduleId);
      if (preserved != null) {
        for (final entry in preserved.entries) {
          try {
            Air()
                .state(entry.key, initialValue: entry.value)
                .setValue(entry.value, sourceModuleId: moduleId);
          } catch (e) {
            AirLogger.warning(
              'Failed to restore state key',
              context: {'key': entry.key, 'error': e.toString()},
            );
          }
        }
      }

      AirLogger.info('Hot reload completed', context: {'moduleId': moduleId});
    } catch (e, stack) {
      AirLogger.error(
        'Hot reload failed',
        context: {'moduleId': moduleId, 'error': e.toString()},
      );
      if (kDebugMode) {
        debugPrintStack(stackTrace: stack);
      }
      rethrow;
    }
  }

  /// Add a listener to be notified before a module is reloaded
  void addReloadListener(String moduleId, VoidCallback callback) {
    _reloadListeners.putIfAbsent(moduleId, () => []).add(callback);
  }

  /// Remove a reload listener
  void removeReloadListener(String moduleId, VoidCallback callback) {
    _reloadListeners[moduleId]?.remove(callback);
  }

  void _notifyListeners(String moduleId) {
    final listeners = _reloadListeners[moduleId];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener();
        } catch (e) {
          AirLogger.error(
            'Error in reload listener',
            context: {'moduleId': moduleId, 'error': e.toString()},
          );
        }
      }
    }
  }

  /// Clear all preserved state (for testing)
  @visibleForTesting
  void clear() {
    if (!kDebugMode) return;
    _preservedState.clear();
    _reloadListeners.clear();
  }
}

/// Mixin to add HMR support to modules
///
/// Example:
/// ```dart
/// class MyModule extends AppModule with HotReloadable {
///   @override
///   List<String> get stateKeysToPreserve => ['my_module.data', 'my_module.user'];
///
///   @override
///   Future<void> onHotReload() async {
///     // Re-subscribe to events, etc.
///   }
/// }
/// ```
mixin HotReloadable {
  /// State keys that should be preserved during hot reload
  List<String> get stateKeysToPreserve => [];

  /// Called after hot reload completes
  Future<void> onHotReload() async {}
}
