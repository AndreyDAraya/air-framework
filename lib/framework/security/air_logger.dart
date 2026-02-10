import 'package:flutter/foundation.dart';

/// Log levels for the Air framework
enum AirLogLevel { debug, info, warning, error, security }

/// Centralized logging system for the Air framework
/// Only logs in debug mode to prevent information exposure in production
class AirLogger {
  static final AirLogger _instance = AirLogger._internal();
  factory AirLogger() => _instance;
  AirLogger._internal();

  /// Whether to enable logging (only in debug mode)
  static bool get _shouldLog => kDebugMode;

  /// Maximum entries to keep in memory for debug tools
  static const int _maxLogEntries = 500;

  /// In-memory log storage for DevTools
  final List<AirLogEntry> _logs = [];

  /// Get logs for DevTools
  List<AirLogEntry> get logs => List.unmodifiable(_logs);

  /// Patterns that should be obfuscated in logs
  static final Set<String> _sensitivePatterns = {
    'token',
    'password',
    'secret',
    'apikey',
    'api_key',
    'credential',
    'auth',
    'session',
    'private',
    'bearer',
  };

  /// Log a debug message
  static void debug(String message, {Map<String, dynamic>? context}) {
    _log(AirLogLevel.debug, 'DBG', message, context: context);
  }

  /// Log an info message
  static void info(String message, {Map<String, dynamic>? context}) {
    _log(AirLogLevel.info, 'INF', message, context: context);
  }

  /// Log a warning message
  static void warning(String message, {Map<String, dynamic>? context}) {
    _log(AirLogLevel.warning, 'WRN', message, context: context);
  }

  /// Log an error message
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(AirLogLevel.error, 'ERR', message, context: context);
    if (error != null && _shouldLog) {
      debugPrint('[AIR:ERR] Error: $error');
    }
    if (stackTrace != null && _shouldLog) {
      debugPrint('[AIR:ERR] StackTrace: $stackTrace');
    }
  }

  /// Log a security-related event
  static void security(String message, {Map<String, dynamic>? context}) {
    _log(AirLogLevel.security, 'SEC', message, context: context);
  }

  // ANSI Color codes for console output
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';

  static const _magenta = '\x1B[35m';
  static const _cyan = '\x1B[36m';

  static final Map<AirLogLevel, String> _levelColors = {
    AirLogLevel.debug: _cyan,
    AirLogLevel.info: _green,
    AirLogLevel.warning: _yellow,
    AirLogLevel.error: _red,
    AirLogLevel.security: _magenta,
  };

  /// Internal log method
  static void _log(
    AirLogLevel level,
    String tag,
    String message, {
    Map<String, dynamic>? context,
  }) {
    if (!_shouldLog) return;

    final sanitizedMessage = _obfuscate(message);
    final sanitizedContext = context != null ? _sanitizeContext(context) : null;

    final entry = AirLogEntry(
      level: level,
      message: sanitizedMessage,
      context: sanitizedContext,
      timestamp: DateTime.now(),
    );

    // Store in memory for DevTools
    AirLogger()._logs.add(entry);
    if (AirLogger()._logs.length > _maxLogEntries) {
      AirLogger()._logs.removeAt(0);
    }

    // Print to console with colors
    final color = _levelColors[level] ?? '';
    final logOutput = '$color[AIR:$tag] $sanitizedMessage$_reset';

    debugPrint(logOutput);

    if (sanitizedContext != null && sanitizedContext.isNotEmpty) {
      debugPrint('$color  Context: $sanitizedContext$_reset');
    }
  }

  /// Obfuscate sensitive data in strings
  static String _obfuscate(String input) {
    String result = input;
    for (final pattern in _sensitivePatterns) {
      // Match pattern followed by : or = and a value
      final regex = RegExp(
        '($pattern)[:\\s=]+[^\\s,}\\]]+',
        caseSensitive: false,
      );
      result = result.replaceAllMapped(
        regex,
        (m) => '${m.group(1)}=[REDACTED]',
      );
    }
    return result;
  }

  /// Sanitize context map
  static Map<String, dynamic> _sanitizeContext(Map<String, dynamic> context) {
    return context.map((key, value) {
      final lowerKey = key.toLowerCase();
      if (_sensitivePatterns.any((p) => lowerKey.contains(p))) {
        return MapEntry(key, '[REDACTED]');
      }
      if (value is String) {
        return MapEntry(key, _obfuscate(value));
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _sanitizeContext(value));
      }
      return MapEntry(key, value);
    });
  }

  /// Clear logs (for testing)
  @visibleForTesting
  void clearLogs() {
    if (!kDebugMode) return;
    _logs.clear();
  }
}

/// A single log entry
class AirLogEntry {
  final AirLogLevel level;
  final String message;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

  AirLogEntry({
    required this.level,
    required this.message,
    this.context,
    required this.timestamp,
  });

  @override
  String toString() => '[${level.name}] $message';
}
