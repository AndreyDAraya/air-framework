import 'package:flutter/foundation.dart';
import 'air_logger.dart';
import 'air_audit.dart';

/// Permission types for module access control.
///
/// This declarative permission system allows modules to define exactly what
/// resources and actions they are authorized to access.
enum Permission {
  /// Permission to read shared data
  dataRead,

  /// Permission to write shared data
  dataWrite,

  /// Permission to call services from other modules
  serviceCall,

  /// Permission to emit events/signals
  eventEmit,

  /// Permission to listen to events/signals
  eventListen,

  /// Permission to access routes
  routeAccess,

  /// Full access (use with caution)
  fullAccess,
}

/// A scoped permission with optional pattern matching
///
/// Example:
/// ```dart
/// ScopedPermission(Permission.serviceCall, 'auth.*') // Access to all auth services
/// ScopedPermission(Permission.dataRead) // Read all shared data
/// ```
class ScopedPermission {
  /// The type of permission
  final Permission permission;

  /// Optional pattern for scoped access (e.g., 'auth.*', 'user.profile')
  /// If null, permission applies to all resources of this type
  final String? pattern;

  const ScopedPermission(this.permission, [this.pattern]);

  /// Check if this permission matches a resource
  bool matches(Permission type, String? resource) {
    if (permission != type && permission != Permission.fullAccess) {
      return false;
    }

    if (pattern == null || resource == null) {
      return true;
    }

    // Support wildcard patterns
    if (pattern!.endsWith('.*')) {
      final prefix = pattern!.substring(0, pattern!.length - 2);
      return resource.startsWith(prefix);
    }

    return pattern == resource;
  }

  @override
  String toString() =>
      'ScopedPermission($permission${pattern != null ? ", $pattern" : ""})';
}

/// Annotation to declare module permissions
///
/// Example:
/// ```dart
/// @ModulePermissions([
///   ScopedPermission(Permission.dataRead),
///   ScopedPermission(Permission.serviceCall, 'auth.*'),
/// ])
/// class ProfileModule extends AppModule { }
/// ```
class ModulePermissions {
  /// List of permissions granted to this module
  final List<ScopedPermission> permissions;

  const ModulePermissions(this.permissions);

  /// Check if this permission set allows a specific action
  bool allows(Permission type, [String? resource]) {
    return permissions.any((p) => p.matches(type, resource));
  }
}

/// Permission checker for the framework
class PermissionChecker {
  static final PermissionChecker _instance = PermissionChecker._();
  factory PermissionChecker() => _instance;
  PermissionChecker._();

  /// Module permissions registry
  final Map<String, ModulePermissions> _modulePermissions = {};

  /// Enable/disable permission checking (disabled in debug mode by default)
  bool _enabled = !kDebugMode;

  /// Enable permission checking
  void enable() => _enabled = true;

  /// Disable permission checking
  void disable() => _enabled = false;

  /// Check if permission checking is enabled
  bool get isEnabled => _enabled;

  /// Register permissions for a module
  void registerModule(String moduleId, ModulePermissions permissions) {
    _modulePermissions[moduleId] = permissions;
    AirLogger.debug(
      'Registered permissions for module',
      context: {
        'moduleId': moduleId,
        'permissions': permissions.permissions
            .map((p) => p.toString())
            .toList(),
      },
    );
  }

  /// Unregister a module's permissions
  void unregisterModule(String moduleId) {
    _modulePermissions.remove(moduleId);
  }

  /// Check if a module has permission for an action
  bool checkPermission(
    String moduleId,
    Permission permission, {
    String? resource,
    bool logViolation = true,
  }) {
    // 1. Allow self-access (module accessing its own resources)
    // If the resource starts with "moduleId.", it's owned by the module.
    if (resource != null &&
        (moduleId == resource || resource.startsWith('$moduleId.'))) {
      return true;
    }

    // 2. Check registered permissions
    final permissions = _modulePermissions[moduleId];
    final allowed = permissions?.allows(permission, resource) ?? false;

    if (!allowed) {
      if (!_enabled) {
        if (logViolation) {
          AirLogger.warning(
            'Permission Bypass (DEBUG): Module "$moduleId" lacks ${permission.name} '
            'permission for ${resource ?? "any resource"}. Register it in the module.',
          );
        }
        return true; // Bypass when disabled (typically in debug)
      }

      if (logViolation) {
        _logViolation(
          moduleId,
          permission,
          resource,
          permissions == null
              ? 'No permissions registered'
              : 'Permission denied',
        );
      }
      return false;
    }

    return true;
  }

  /// Check permission and throw if denied
  void requirePermission(
    String moduleId,
    Permission permission, {
    String? resource,
  }) {
    if (!checkPermission(moduleId, permission, resource: resource)) {
      throw PermissionDeniedException(
        moduleId: moduleId,
        permission: permission,
        resource: resource,
      );
    }
  }

  void _logViolation(
    String moduleId,
    Permission permission,
    String? resource,
    String reason,
  ) {
    AirLogger.warning(
      'Permission violation',
      context: {
        'moduleId': moduleId,
        'permission': permission.name,
        'resource': resource,
        'reason': reason,
      },
    );

    AirAudit().log(
      type: AuditType.securityViolation,
      action: 'permission_denied',
      moduleId: moduleId,
      context: {
        'permission': permission.name,
        'resource': resource,
        'reason': reason,
      },
      severity: AuditSeverity.medium,
      success: false,
    );
  }

  /// Get all permissions for a module
  ModulePermissions? getModulePermissions(String moduleId) {
    return _modulePermissions[moduleId];
  }

  /// Get all registered modules
  List<String> get registeredModules => _modulePermissions.keys.toList();

  /// Clear all permissions (for testing)
  @visibleForTesting
  void clear() {
    if (!kDebugMode) {
      AirLogger.warning(
        'PermissionChecker.clear() called in release mode - ignored',
      );
      return;
    }
    _modulePermissions.clear();
  }
}

/// Exception thrown when permission is denied
class PermissionDeniedException implements Exception {
  final String moduleId;
  final Permission permission;
  final String? resource;

  PermissionDeniedException({
    required this.moduleId,
    required this.permission,
    this.resource,
  });

  @override
  String toString() =>
      'PermissionDeniedException: Module "$moduleId" does not have '
      '${permission.name} permission${resource != null ? " for resource: $resource" : ""}';
}
