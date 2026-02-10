import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Log level enum
enum LogLevel { debug, info, warning, error }

/// A single log entry
class LogEntry {
  final DateTime timestamp;
  final String moduleId;
  final LogLevel level;
  final String message;
  final Object? data;
  final StackTrace? stackTrace;

  LogEntry({
    required this.moduleId,
    required this.level,
    required this.message,
    this.data,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    final levelStr = level.name.toUpperCase().padRight(7);
    return '[$time] $levelStr [$moduleId] $message';
  }

  String get emoji {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}

/// Centralized logger for modules
class ModuleLogger extends ChangeNotifier {
  static final ModuleLogger _instance = ModuleLogger._internal();
  factory ModuleLogger() => _instance;
  ModuleLogger._internal();

  final Queue<LogEntry> _logs = Queue<LogEntry>();
  final int _maxLogs = 500;

  LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool printToConsole = true;

  /// Get all logs
  List<LogEntry> get logs => _logs.toList();

  /// Get logs filtered by module
  List<LogEntry> getModuleLogs(String moduleId) {
    return _logs.where((log) => log.moduleId == moduleId).toList();
  }

  /// Get logs filtered by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level.index >= level.index).toList();
  }

  void _log(LogEntry entry) {
    if (entry.level.index < minLevel.index) return;

    _logs.addLast(entry);
    while (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }

    if (printToConsole) {
      debugPrint('${entry.emoji} $entry');
      if (entry.data != null) {
        debugPrint('   Data: ${entry.data}');
      }
      if (entry.stackTrace != null) {
        debugPrint(entry.stackTrace.toString());
      }
    }

    notifyListeners();
  }

  /// Log debug message
  void debug(String moduleId, String message, {Object? data}) {
    _log(
      LogEntry(
        moduleId: moduleId,
        level: LogLevel.debug,
        message: message,
        data: data,
      ),
    );
  }

  /// Log info message
  void info(String moduleId, String message, {Object? data}) {
    _log(
      LogEntry(
        moduleId: moduleId,
        level: LogLevel.info,
        message: message,
        data: data,
      ),
    );
  }

  /// Log warning message
  void warning(String moduleId, String message, {Object? data}) {
    _log(
      LogEntry(
        moduleId: moduleId,
        level: LogLevel.warning,
        message: message,
        data: data,
      ),
    );
  }

  /// Log error message
  void error(
    String moduleId,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogEntry(
        moduleId: moduleId,
        level: LogLevel.error,
        message: message,
        data: error,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Clear all logs
  void clear() {
    _logs.clear();
    notifyListeners();
  }

  /// Export logs as string
  String export() {
    return _logs.map((log) => log.toString()).join('\n');
  }
}

/// Mixin for modules to easily access logging
mixin ModuleLogging {
  String get logModuleId;

  ModuleLogger get _logger => ModuleLogger();

  void logDebug(String message, {Object? data}) {
    _logger.debug(logModuleId, message, data: data);
  }

  void logInfo(String message, {Object? data}) {
    _logger.info(logModuleId, message, data: data);
  }

  void logWarning(String message, {Object? data}) {
    _logger.warning(logModuleId, message, data: data);
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.error(logModuleId, message, error: error, stackTrace: stackTrace);
  }
}
