import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'air_logger.dart';
import 'air_audit.dart';
import 'permissions.dart';

/// Type of interaction between modules
enum InteractionType { service, event, data }

/// Represents an interaction between two modules
class ModuleInteraction {
  final String sourceId;
  final String targetId;
  final InteractionType type;
  final String detail;
  final DateTime timestamp;

  ModuleInteraction({
    required this.sourceId,
    required this.targetId,
    required this.type,
    required this.detail,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Wrapper for secure data storage with encryption and expiration support.
class SecureData<T> {
  final T value;
  final bool isEncrypted;
  final DateTime? expiresAt;
  final String ownerModuleId;

  SecureData(
    this.value, {
    this.isEncrypted = false,
    this.expiresAt,
    required this.ownerModuleId,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Descriptor for a service that can be registered
class SecureServiceDescriptor {
  final String name;
  final String ownerModuleId;
  final Function service;
  final List<String> allowedCallers; // Empty = public

  SecureServiceDescriptor({
    required this.name,
    required this.ownerModuleId,
    required this.service,
    this.allowedCallers = const [],
  });

  bool get isPublic => allowedCallers.isEmpty;
}

/// A secure service registry for modules with audit logging
class SecureServiceRegistry extends ChangeNotifier {
  static final SecureServiceRegistry _instance =
      SecureServiceRegistry._internal();
  factory SecureServiceRegistry() => _instance;
  SecureServiceRegistry._internal();

  final Map<String, SecureServiceDescriptor> _services = {};
  final Map<String, dynamic> _sharedData = {};
  final Map<String, List<VoidCallback>> _dataListeners = {};

  // Interactions history for AirGraph
  final List<ModuleInteraction> _interactions = [];
  List<ModuleInteraction> get interactions => List.unmodifiable(_interactions);

  // Persistent relationships discovered (sourceId -> targetId) with timestamps.
  // Includes timestamp tracking and size limits to prevent memory leaks.
  static const int _maxRelationships = 500;
  final Map<String, DateTime> _relationshipsWithTimestamp = {};
  Set<String> get relationships => _relationshipsWithTimestamp.keys.toSet();

  // Patterns of keys considered sensitive that require auditing and special handling.
  static final Set<String> _sensitiveKeyPatterns = {
    'auth.',
    'token',
    'password',
    'credential',
    'secret',
    'apikey',
    'session',
    'private',
  };

  /// Check if a key is considered sensitive
  bool _isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();
    return _sensitiveKeyPatterns.any((pattern) => lowerKey.contains(pattern));
  }

  void recordInteraction(ModuleInteraction interaction) {
    _interactions.add(interaction);
    if (_interactions.length > 100) _interactions.removeAt(0);

    // Record persistent relationship with timestamp
    final relationKey = '${interaction.sourceId}->${interaction.targetId}';
    _relationshipsWithTimestamp[relationKey] = DateTime.now();

    // Clean up old relationships if the size limit is exceeded.
    _cleanOldRelationships();

    _safeNotify();
  }

  /// Periodically clean up old relationships when the limit is reached.
  void _cleanOldRelationships() {
    if (_relationshipsWithTimestamp.length <= _maxRelationships) return;

    // Sort by timestamp and keep only the most recent
    final sorted = _relationshipsWithTimestamp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _relationshipsWithTimestamp.clear();
    for (var i = 0; i < _maxRelationships && i < sorted.length; i++) {
      _relationshipsWithTimestamp[sorted[i].key] = sorted[i].value;
    }
  }

  /// Safely notify listeners, deferring if called during build
  void _safeNotify() {
    // Use addPostFrameCallback to defer notification if in build phase
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Get all registered service descriptors (for debugging)
  List<SecureServiceDescriptor> get registeredServices =>
      _services.values.toList();

  /// Register a service
  void registerService({
    required String name,
    required String ownerModuleId,
    required Function service,
    List<String> allowedCallers = const [],
  }) {
    _services[name] = SecureServiceDescriptor(
      name: name,
      ownerModuleId: ownerModuleId,
      service: service,
      allowedCallers: allowedCallers,
    );
    AirLogger.debug(
      'Service registered: $name',
      context: {'owner': ownerModuleId, 'public': allowedCallers.isEmpty},
    );
    _safeNotify();
  }

  /// Get a service with proper access control
  T? getService<T>(String serviceName, {required String callerModuleId}) {
    final descriptor = _services[serviceName];
    if (descriptor == null) {
      AirLogger.warning('Service not found: $serviceName');
      return null;
    }

    // Check if caller is allowed (simple isolation)
    final isAllowedByDescriptor =
        descriptor.isPublic ||
        descriptor.allowedCallers.contains(callerModuleId);

    // Check permission checker
    final isAllowedByPermission = PermissionChecker().checkPermission(
      callerModuleId,
      Permission.serviceCall,
      resource: serviceName,
    );

    final isAllowed = isAllowedByDescriptor && isAllowedByPermission;

    // Audit the access attempt
    AirAudit().logServiceAccess(
      serviceName: serviceName,
      callerModuleId: callerModuleId,
      ownerModuleId: descriptor.ownerModuleId,
      granted: isAllowed,
    );

    if (!isAllowed) {
      AirLogger.security(
        'Access denied: $callerModuleId not authorized to call $serviceName',
      );
      return null;
    }

    // Record interaction for AirGraph
    recordInteraction(
      ModuleInteraction(
        sourceId: callerModuleId,
        targetId: descriptor.ownerModuleId,
        type: InteractionType.service,
        detail: serviceName,
      ),
    );

    AirLogger.debug(
      'Service access granted',
      context: {'caller': callerModuleId, 'service': serviceName},
    );
    return descriptor.service as T?;
  }

  /// Check if a service exists
  bool hasService(String serviceName) => _services.containsKey(serviceName);

  /// Get service descriptor
  SecureServiceDescriptor? getDescriptor(String serviceName) =>
      _services[serviceName];

  /// Unregister a service
  void unregisterService(String serviceName, {required String callerModuleId}) {
    final descriptor = _services[serviceName];
    if (descriptor == null) return;

    // Only owner can unregister
    if (descriptor.ownerModuleId != callerModuleId) {
      AirLogger.warning(
        'Cannot unregister: $callerModuleId is not owner of $serviceName',
      );
      return;
    }

    _services.remove(serviceName);
    AirLogger.debug('Service unregistered: $serviceName');
    notifyListeners();
  }

  /// Unregister all services from a module
  void unregisterModuleServices(String moduleId) {
    final toRemove = _services.entries
        .where((e) => e.value.ownerModuleId == moduleId)
        .map((e) => e.key)
        .toList();

    for (final name in toRemove) {
      _services.remove(name);
      AirLogger.debug('Service unregistered: $name');
    }

    if (toRemove.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Get all services registered by a module
  List<SecureServiceDescriptor> getModuleServices(String moduleId) {
    return _services.values.where((s) => s.ownerModuleId == moduleId).toList();
  }

  /// Get all available services for a caller
  List<SecureServiceDescriptor> getAvailableServices(String callerModuleId) {
    return _services.values.where((s) {
      if (!s.isPublic && !s.allowedCallers.contains(callerModuleId)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ============ Shared Data Methods ============

  /// Sets shared data with optional encryption and Time-to-Live (TTL).
  void setSecureData<T>(
    String key,
    T value, {
    required String callerModuleId,
    bool encrypt = false,
    Duration? ttl,
  }) {
    final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;

    // In a real implementation, 'encrypt' would use a secure vault.
    // For now, we wrap it in SecureData which provides the metadata.
    _sharedData[key] = SecureData<T>(
      value,
      isEncrypted: encrypt,
      expiresAt: expiresAt,
      ownerModuleId: callerModuleId,
    );

    _notifyDataListeners(key);

    if (_isSensitiveKey(key) || encrypt) {
      AirAudit().logSensitiveDataAccess(
        dataKey: key,
        callerModuleId: callerModuleId,
        reason: 'set_secure_data',
      );
    }

    AirLogger.debug(
      'Secure data set: $key',
      context: {
        'caller': callerModuleId,
        'encrypted': encrypt,
        'ttl': ttl?.inSeconds,
      },
    );
  }

  /// Retrieves shared data, handling SecureData wrappers and automatic expiration.
  T? getSecureData<T>(String key, {required String callerModuleId}) {
    final data = _sharedData[key];

    if (data == null) return null;

    if (data is SecureData) {
      if (data.isExpired) {
        AirLogger.debug('Secure data expired: $key');
        _sharedData.remove(key);
        return null;
      }

      if (_isSensitiveKey(key) || data.isEncrypted) {
        AirAudit().logSensitiveDataAccess(
          dataKey: key,
          callerModuleId: callerModuleId,
          reason: 'get_secure_data',
        );
      }

      try {
        return data.value as T?;
      } catch (e) {
        AirLogger.error('Type mismatch for secure data: $key', error: e);
        return null;
      }
    }

    // Fallback for legacy data
    return getData<T>(key, callerModuleId: callerModuleId);
  }

  /// Set shared data (legacy compatibility)
  void setData(String key, dynamic value, {required String callerModuleId}) {
    _sharedData[key] = value;
    _notifyDataListeners(key);

    // Log sensitive data access
    if (_isSensitiveKey(key)) {
      AirAudit().logSensitiveDataAccess(
        dataKey: key,
        callerModuleId: callerModuleId,
        reason: 'set_data',
      );
    }

    AirLogger.debug(
      'Shared data set: $key',
      context: {'caller': callerModuleId},
    );
  }

  /// Get shared data with proper tracking
  T? getData<T>(String key, {required String callerModuleId}) {
    // Log sensitive data access
    if (_isSensitiveKey(key)) {
      AirAudit().logSensitiveDataAccess(
        dataKey: key,
        callerModuleId: callerModuleId,
        reason: 'get_data',
      );
    }
    return _sharedData[key] as T?;
  }

  /// Add listener for data changes
  void addDataListener(String key, VoidCallback callback) {
    _dataListeners.putIfAbsent(key, () => []);
    _dataListeners[key]!.add(callback);
  }

  /// Remove listener
  void removeDataListener(String key, VoidCallback callback) {
    _dataListeners[key]?.remove(callback);
  }

  void _notifyDataListeners(String key) {
    for (var callback in _dataListeners[key] ?? []) {
      callback();
    }
  }

  /// Clear all registry state. PROTECTED: Only available in debug/test environments.
  @visibleForTesting
  void clearAll() {
    // Only allow in debug mode to prevent accidental production resets
    if (!kDebugMode) {
      AirLogger.warning('clearAll() called in release mode - ignored');
      return;
    }

    _services.clear();
    _sharedData.clear();
    _dataListeners.clear();
    _relationshipsWithTimestamp.clear();
    _interactions.clear();
    notifyListeners();
  }
}
