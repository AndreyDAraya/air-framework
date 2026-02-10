import '../security/air_logger.dart';
import '../state/air.dart';

/// Analytics integration for Air Framework
/// MEJORA-011: Export a Analytics
///
/// Abstract adapter for analytics integration.
///
/// Example:
/// ```dart
/// // Configure with Firebase
/// AirAnalytics().configure(FirebaseAnalyticsAdapter(analytics));
/// AirAnalytics().enable();
///
/// // Now all state changes and signals are tracked
/// ```
abstract class AirAnalyticsAdapter {
  /// Log a custom event
  void logEvent(String name, Map<String, dynamic>? parameters);

  /// Log a state change
  void logStateChange(String key, dynamic oldValue, dynamic newValue);

  /// Log a signal emission
  void logSignal(String signalName, dynamic data);

  /// Log a module interaction
  void logModuleInteraction(String source, String target, String type);
}

/// Analytics manager for Air Framework
class AirAnalytics {
  static final AirAnalytics _instance = AirAnalytics._();
  factory AirAnalytics() => _instance;
  AirAnalytics._();

  AirAnalyticsAdapter? _adapter;
  bool _enabled = false;

  // Observers
  String? _stateObserverId;
  String? _actionObserverId;

  /// Configure the analytics adapter
  void configure(AirAnalyticsAdapter adapter) {
    _adapter = adapter;
    AirLogger.debug('Analytics adapter configured');
  }

  /// Enable analytics tracking
  void enable() {
    if (_adapter == null) {
      AirLogger.warning('Cannot enable analytics: no adapter configured');
      return;
    }

    if (_enabled) return;
    _enabled = true;

    // Setup state change tracking
    _stateObserverId = Air().addStateObserver((key, value) {
      _adapter?.logStateChange(key, null, value);
    });

    // Setup action/pulse tracking
    _actionObserverId = Air().addActionObserver((action, data) {
      _adapter?.logSignal(action, data);
    });

    AirLogger.debug('Analytics tracking enabled');
  }

  /// Disable analytics tracking
  void disable() {
    if (!_enabled) return;
    _enabled = false;

    // Remove observers
    if (_stateObserverId != null) {
      Air().removeStateObserverById(_stateObserverId!);
      _stateObserverId = null;
    }

    if (_actionObserverId != null) {
      Air().removeActionObserverById(_actionObserverId!);
      _actionObserverId = null;
    }

    AirLogger.debug('Analytics tracking disabled');
  }

  /// Check if analytics is enabled
  bool get isEnabled => _enabled;

  /// Check if adapter is configured
  bool get isConfigured => _adapter != null;

  /// Log a custom event
  void logEvent(String name, [Map<String, dynamic>? parameters]) {
    if (_enabled && _adapter != null) {
      _adapter!.logEvent(name, parameters);
    }
  }

  /// Log a screen view
  void logScreenView(String screenName, [String? screenClass]) {
    logEvent('screen_view', {
      'screen_name': screenName,
      'screen_class': screenClass,
    });
  }

  /// Log a user action
  void logUserAction(String action, [Map<String, dynamic>? context]) {
    logEvent('user_action', {'action': action, ...?context});
  }
}

/// Console-based analytics adapter for development
class ConsoleAnalyticsAdapter implements AirAnalyticsAdapter {
  final bool verbose;

  const ConsoleAnalyticsAdapter({this.verbose = false});

  @override
  void logEvent(String name, Map<String, dynamic>? parameters) {
    AirLogger.debug('[Analytics] Event: $name', context: parameters);
  }

  @override
  void logStateChange(String key, dynamic oldValue, dynamic newValue) {
    if (verbose) {
      AirLogger.debug(
        '[Analytics] State: $key',
        context: {'old': oldValue?.toString(), 'new': newValue?.toString()},
      );
    }
  }

  @override
  void logSignal(String signalName, dynamic data) {
    AirLogger.debug(
      '[Analytics] Signal: $signalName',
      context: {'data': data?.toString()},
    );
  }

  @override
  void logModuleInteraction(String source, String target, String type) {
    AirLogger.debug(
      '[Analytics] Interaction: $source -> $target',
      context: {'type': type},
    );
  }
}

/// Batching analytics adapter that collects events before sending
class BatchingAnalyticsAdapter implements AirAnalyticsAdapter {
  final AirAnalyticsAdapter _delegate;
  final int batchSize;
  final Duration maxDelay;

  final List<_AnalyticsEvent> _batch = [];
  DateTime? _batchStart;

  BatchingAnalyticsAdapter(
    this._delegate, {
    this.batchSize = 10,
    this.maxDelay = const Duration(seconds: 30),
  });

  void _addToBatch(_AnalyticsEvent event) {
    _batch.add(event);
    _batchStart ??= DateTime.now();

    if (_batch.length >= batchSize || _shouldFlush()) {
      flush();
    }
  }

  bool _shouldFlush() {
    if (_batchStart == null) return false;
    return DateTime.now().difference(_batchStart!) > maxDelay;
  }

  /// Manually flush the batch
  void flush() {
    for (final event in _batch) {
      event.send(_delegate);
    }
    _batch.clear();
    _batchStart = null;
  }

  @override
  void logEvent(String name, Map<String, dynamic>? parameters) {
    _addToBatch(_EventLog(name, parameters));
  }

  @override
  void logStateChange(String key, dynamic oldValue, dynamic newValue) {
    _addToBatch(_StateChangeLog(key, oldValue, newValue));
  }

  @override
  void logSignal(String signalName, dynamic data) {
    _addToBatch(_SignalLog(signalName, data));
  }

  @override
  void logModuleInteraction(String source, String target, String type) {
    _addToBatch(_InteractionLog(source, target, type));
  }
}

// Internal event types for batching
abstract class _AnalyticsEvent {
  void send(AirAnalyticsAdapter adapter);
}

class _EventLog implements _AnalyticsEvent {
  final String name;
  final Map<String, dynamic>? parameters;
  _EventLog(this.name, this.parameters);
  @override
  void send(AirAnalyticsAdapter adapter) => adapter.logEvent(name, parameters);
}

class _StateChangeLog implements _AnalyticsEvent {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  _StateChangeLog(this.key, this.oldValue, this.newValue);
  @override
  void send(AirAnalyticsAdapter adapter) =>
      adapter.logStateChange(key, oldValue, newValue);
}

class _SignalLog implements _AnalyticsEvent {
  final String signalName;
  final dynamic data;
  _SignalLog(this.signalName, this.data);
  @override
  void send(AirAnalyticsAdapter adapter) => adapter.logSignal(signalName, data);
}

class _InteractionLog implements _AnalyticsEvent {
  final String source;
  final String target;
  final String type;
  _InteractionLog(this.source, this.target, this.type);
  @override
  void send(AirAnalyticsAdapter adapter) =>
      adapter.logModuleInteraction(source, target, type);
}
