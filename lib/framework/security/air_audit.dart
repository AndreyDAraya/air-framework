import 'package:flutter/foundation.dart';

/// Audit severity levels
enum AuditSeverity { low, medium, high, critical }

/// Types of audit events
enum AuditType {
  serviceAccess,
  dataAccess,
  sensitiveDataAccess,
  moduleInteraction,
  securityViolation,
  configChange,
}

/// A single audit entry
class AuditEntry {
  final String id;
  final AuditType type;
  final String action;
  final String moduleId;
  final String? targetModuleId;
  final Map<String, dynamic>? context;
  final AuditSeverity severity;
  final DateTime timestamp;
  final bool success;

  AuditEntry({
    required this.type,
    required this.action,
    required this.moduleId,
    this.targetModuleId,
    this.context,
    this.severity = AuditSeverity.low,
    this.success = true,
  }) : id = _generateId(),
       timestamp = DateTime.now();

  static int _idCounter = 0;
  static String _generateId() => 'audit_${++_idCounter}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'action': action,
    'moduleId': moduleId,
    'targetModuleId': targetModuleId,
    'context': context,
    'severity': severity.name,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
  };
}

/// Centralized audit logging for security-sensitive operations
class AirAudit extends ChangeNotifier {
  static final AirAudit _instance = AirAudit._internal();
  factory AirAudit() => _instance;
  AirAudit._internal();

  /// Maximum audit entries to retain
  static const int _maxEntries = 1000;

  /// Audit log storage
  final List<AuditEntry> _entries = [];

  /// Get all audit entries
  List<AuditEntry> get entries => List.unmodifiable(_entries);

  /// Get entries count
  int get count => _entries.length;

  /// Log a security audit event
  void log({
    required AuditType type,
    required String action,
    required String moduleId,
    String? targetModuleId,
    Map<String, dynamic>? context,
    AuditSeverity severity = AuditSeverity.low,
    bool success = true,
  }) {
    final entry = AuditEntry(
      type: type,
      action: action,
      moduleId: moduleId,
      targetModuleId: targetModuleId,
      context: context,
      severity: severity,
      success: success,
    );

    _entries.add(entry);

    // Trim old entries
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }

    // Log critical events
    if (severity == AuditSeverity.critical && kDebugMode) {
      debugPrint('[AUDIT:CRITICAL] $action by $moduleId');
    }

    notifyListeners();
  }

  /// Log a service access
  void logServiceAccess({
    required String serviceName,
    required String callerModuleId,
    required String ownerModuleId,
    required bool granted,
  }) {
    log(
      type: AuditType.serviceAccess,
      action: 'service_access:$serviceName',
      moduleId: callerModuleId,
      targetModuleId: ownerModuleId,
      context: {'service': serviceName, 'granted': granted},
      severity: granted ? AuditSeverity.low : AuditSeverity.medium,
      success: granted,
    );
  }

  /// Log a sensitive data access
  void logSensitiveDataAccess({
    required String dataKey,
    required String callerModuleId,
    String? reason,
  }) {
    log(
      type: AuditType.sensitiveDataAccess,
      action: 'sensitive_data_access:$dataKey',
      moduleId: callerModuleId,
      context: {'key': dataKey, 'reason': reason ?? 'Not specified'},
      severity: AuditSeverity.high,
    );
  }

  /// Log a security violation
  void logSecurityViolation({
    required String violation,
    required String moduleId,
    Map<String, dynamic>? context,
  }) {
    log(
      type: AuditType.securityViolation,
      action: violation,
      moduleId: moduleId,
      context: context,
      severity: AuditSeverity.critical,
      success: false,
    );
  }

  /// Query audit entries
  List<AuditEntry> query({
    String? moduleId,
    AuditType? type,
    DateTime? since,
    DateTime? until,
    AuditSeverity? minSeverity,
    bool? successOnly,
  }) {
    return _entries.where((e) {
      if (moduleId != null && e.moduleId != moduleId) return false;
      if (type != null && e.type != type) return false;
      if (since != null && e.timestamp.isBefore(since)) return false;
      if (until != null && e.timestamp.isAfter(until)) return false;
      if (minSeverity != null && e.severity.index < minSeverity.index) {
        return false;
      }
      if (successOnly != null && e.success != successOnly) return false;
      return true;
    }).toList();
  }

  /// Get recent violations
  List<AuditEntry> get recentViolations {
    return _entries
        .where((e) => e.type == AuditType.securityViolation)
        .toList()
        .reversed
        .take(20)
        .toList();
  }

  /// Clear all entries (for testing)
  @visibleForTesting
  void clear() {
    if (!kDebugMode) return;
    _entries.clear();
    notifyListeners();
  }
}
