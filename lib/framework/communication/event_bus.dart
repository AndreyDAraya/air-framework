import 'dart:async';
import 'package:flutter/foundation.dart';
import '../security/secure_service_registry.dart';
import '../security/air_logger.dart';
import '../security/air_audit.dart';
import '../security/identity.dart';
import '../security/permissions.dart';

/// Base class for all module events
abstract class ModuleEvent {
  final String sourceModuleId;
  final DateTime timestamp;

  ModuleEvent({required this.sourceModuleId, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

/// Recorded signal for history
class SignalHistoryEntry {
  final String name;
  final dynamic data;
  final DateTime timestamp;
  final String? sourceModuleId;

  SignalHistoryEntry({required this.name, this.data, this.sourceModuleId})
    : timestamp = DateTime.now();
}

/// Configuration for event rate limiting to prevent system flooding.
class RateLimitConfig {
  final Duration window;
  final int maxEvents;

  const RateLimitConfig({
    this.window = const Duration(seconds: 1),
    this.maxEvents = 100,
  });
}

/// Event subscription that can be cancelled or automatically expire.
class EventSubscription {
  final String id;
  final Type eventType;
  final Function callback;
  final String? subscriberModuleId;
  final DateTime createdAt;
  final Duration? timeout;
  bool _cancelled = false;

  EventSubscription({
    required this.id,
    required this.eventType,
    required this.callback,
    this.subscriberModuleId,
    this.timeout,
  }) : createdAt = DateTime.now();

  bool get isCancelled => _cancelled;

  /// Check if the subscription has exceeded its defined timeout.
  bool get isExpired {
    if (timeout == null) return false;
    return DateTime.now().difference(createdAt) > timeout!;
  }

  void cancel() {
    _cancelled = true;
  }
}

/// A typed event bus for inter-module communication.
///
/// Features:
/// * **Source Verification**: Ensures events and signals come from the claimed module.
/// * **Rate Limiting**: Protects against message loops or flood attacks.
/// * **Auto-Cleanup**: Automatically expires old or orphaned subscriptions.
/// * **Middleware Support**: Intercepts and modifies events or signals in-flight.
///
/// [event] - The event being processed
/// [next] - Callback to continue the middleware chain
///
/// Example:
/// ```dart
/// EventBus().addMiddleware((event, next) {
///   print('Before: ${event.runtimeType}');
///   next(event); // Continue chain
///   print('After: ${event.runtimeType}');
/// });
/// ```
typedef EventMiddleware =
    void Function(dynamic event, void Function(dynamic) next);

/// Middleware for signal interception.
typedef SignalMiddleware =
    void Function(
      String signalName,
      dynamic data,
      void Function(String, dynamic) next,
    );

class EventBus extends ChangeNotifier {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal() {
    // Start cleanup timer for expired subscriptions
    _startCleanupTimer();
  }

  final Map<Type, List<EventSubscription>> _subscriptions = {};
  final Map<String, List<EventSubscription>> _signalSubscriptions = {};
  final List<ModuleEvent> _eventHistory = [];
  final List<SignalHistoryEntry> _signalHistory = [];
  final int _maxHistorySize = 100;

  int _subscriptionIdCounter = 0;

  // Internal histories for rate limiting
  final Map<String, List<DateTime>> _emitHistory = {};
  RateLimitConfig _rateLimitConfig = const RateLimitConfig();

  // Internal timer for periodic cleanup
  Timer? _cleanupTimer;

  // Middleware registries for intercepting events and signals
  final List<EventMiddleware> _eventMiddlewares = [];
  final List<SignalMiddleware> _signalMiddlewares = [];

  /// Add an event middleware for processing or filtering events.
  ///
  /// Middlewares are called in order for every event emission.
  /// Each middleware must call `next(event)` to continue the chain.
  ///
  /// Example:
  /// ```dart
  /// EventBus().addMiddleware((event, next) {
  ///   logger.log('Event: ${event.runtimeType}');
  ///   next(event); // Continue chain - omit to cancel
  /// });
  /// ```
  void addMiddleware(EventMiddleware middleware) {
    _eventMiddlewares.add(middleware);
  }

  /// Remove an event middleware from the chain.
  void removeMiddleware(EventMiddleware middleware) {
    _eventMiddlewares.remove(middleware);
  }

  /// Add a signal middleware for processing or filtering named signals.
  ///
  /// Middlewares are called in order for every signal emission.
  ///
  /// Example:
  /// ```dart
  /// EventBus().addSignalMiddleware((name, data, next) {
  ///   if (name.startsWith('auth.')) {
  ///     logger.log('Auth signal: $name');
  ///   }
  ///   next(name, data);
  /// });
  /// ```
  void addSignalMiddleware(SignalMiddleware middleware) {
    _signalMiddlewares.add(middleware);
  }

  /// Remove a signal middleware from the chain.
  void removeSignalMiddleware(SignalMiddleware middleware) {
    _signalMiddlewares.remove(middleware);
  }

  /// Get current middleware counts for debugging and monitoring.
  int get eventMiddlewareCount => _eventMiddlewares.length;
  int get signalMiddlewareCount => _signalMiddlewares.length;

  /// Configure rate limiting
  void setRateLimitConfig(RateLimitConfig config) {
    _rateLimitConfig = config;
  }

  /// Internal check to enforce rate limits per module/event type.
  bool _checkRateLimit(String key) {
    final now = DateTime.now();
    final history = _emitHistory.putIfAbsent(key, () => []);

    // Remove events outside the window
    history.removeWhere(
      (timestamp) => now.difference(timestamp) > _rateLimitConfig.window,
    );

    if (history.length >= _rateLimitConfig.maxEvents) {
      AirLogger.warning(
        'Rate limit exceeded',
        context: {'key': key, 'limit': _rateLimitConfig.maxEvents},
      );
      return false;
    }

    history.add(now);
    return true;
  }

  /// Starts a periodic background task to remove expired or cancelled subscriptions.
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanExpiredSubscriptions();
    });
  }

  /// Iterates through all subscriptions and removes those that are no longer valid.
  void _cleanExpiredSubscriptions() {
    int cleanedCount = 0;

    for (final subs in _subscriptions.values) {
      subs.removeWhere((sub) {
        if (sub.isExpired || sub.isCancelled) {
          sub.cancel();
          cleanedCount++;
          return true;
        }
        return false;
      });
    }

    for (final subs in _signalSubscriptions.values) {
      subs.removeWhere((sub) {
        if (sub.isExpired || sub.isCancelled) {
          sub.cancel();
          cleanedCount++;
          return true;
        }
        return false;
      });
    }

    if (cleanedCount > 0) {
      AirLogger.debug(
        'Cleaned expired subscriptions',
        context: {'count': cleanedCount},
      );
    }
  }

  /// Subscribe to events of a specific type
  /// Returns a subscription that can be cancelled
  ///
  /// [timeout] - Optional duration after which the subscription auto-expires
  EventSubscription on<T extends ModuleEvent>(
    void Function(T event) callback, {
    String? subscriberModuleId,
    Duration? timeout,
  }) {
    // Check permission
    if (!PermissionChecker().checkPermission(
      subscriberModuleId ?? 'unknown',
      Permission.eventListen,
      resource: T.toString(),
    )) {
      AirLogger.warning(
        'Subscription denied: $subscriberModuleId lacks eventListen permission for $T',
      );
      // Return a dummy cancelled subscription
      final dummy = EventSubscription(
        id: 'denied',
        eventType: T,
        callback: (_) {},
      );
      dummy.cancel();
      return dummy;
    }

    final subscription = EventSubscription(
      id: 'sub_${++_subscriptionIdCounter}',
      eventType: T,
      callback: callback,
      subscriberModuleId: subscriberModuleId,
      timeout: timeout,
    );

    _subscriptions.putIfAbsent(T, () => []);
    _subscriptions[T]!.add(subscription);

    AirLogger.debug(
      'Subscribed to ${T.toString()}',
      context: {
        'id': subscription.id,
        'module': subscriberModuleId,
        'timeout': timeout?.inSeconds,
      },
    );
    return subscription;
  }

  /// Subscribe to a named signal (String-based event)
  /// Use this for zero-import communication between modules
  EventSubscription onSignal(
    String signalName,
    void Function(dynamic data) callback, {
    String? subscriberModuleId,
    Duration? timeout,
  }) {
    // Check permission
    if (!PermissionChecker().checkPermission(
      subscriberModuleId ?? 'unknown',
      Permission.eventListen,
      resource: signalName,
    )) {
      AirLogger.warning(
        'Signal subscription denied: $subscriberModuleId lacks eventListen permission for $signalName',
      );
      final dummy = EventSubscription(
        id: 'denied',
        eventType: dynamic,
        callback: (_) {},
      );
      dummy.cancel();
      return dummy;
    }

    final subscription = EventSubscription(
      id: 'signal_${++_subscriptionIdCounter}',
      eventType: dynamic, // Using dynamic as a placeholder for string signals
      callback: callback,
      subscriberModuleId: subscriberModuleId,
      timeout: timeout,
    );

    _signalSubscriptions.putIfAbsent(signalName, () => []);
    _signalSubscriptions[signalName]!.add(subscription);

    AirLogger.debug(
      'Subscribed to signal "$signalName"',
      context: {'id': subscription.id, 'module': subscriberModuleId},
    );
    return subscription;
  }

  /// Subscribe to events and auto-dispose when widget is disposed
  /// Use with StatefulWidget's dispose method
  EventSubscription onAutoDispose<T extends ModuleEvent>(
    void Function(T event) callback, {
    String? subscriberModuleId,
    Duration? timeout,
  }) {
    return on<T>(
      callback,
      subscriberModuleId: subscriberModuleId,
      timeout: timeout,
    );
  }

  /// Emit an event to all subscribers with built-in rate limiting protection.
  void emit<T extends ModuleEvent>(T event) {
    // Check rate limit per source module and event type
    final rateLimitKey = '${event.sourceModuleId}:${T.toString()}';
    if (!_checkRateLimit(rateLimitKey)) {
      AirAudit().log(
        type: AuditType.securityViolation,
        action: 'event_rate_limit_exceeded',
        moduleId: event.sourceModuleId,
        context: {'eventType': T.toString()},
        severity: AuditSeverity.medium,
        success: false,
      );
      return;
    }

    // Check permission to emit
    if (!PermissionChecker().checkPermission(
      event.sourceModuleId,
      Permission.eventEmit,
      resource: T.toString(),
    )) {
      return;
    }

    AirLogger.debug(
      'Emitting ${event.runtimeType}',
      context: {'source': event.sourceModuleId},
    );

    // Add to history
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeAt(0);
    }

    // Notify subscribers
    final subs = _subscriptions[T];
    if (subs == null || subs.isEmpty) {
      AirLogger.debug('No subscribers for ${event.runtimeType}');
      return;
    }

    // Create copy of active subscribers to iterate safely, then clean up cancelled/expired
    final activeSubs = subs
        .where((s) => !s.isCancelled && !s.isExpired)
        .toList();
    subs.removeWhere((s) => s.isCancelled || s.isExpired);

    for (final subscription in activeSubs) {
      if (subscription.subscriberModuleId != null) {
        SecureServiceRegistry().recordInteraction(
          ModuleInteraction(
            sourceId: event.sourceModuleId,
            targetId: subscription.subscriberModuleId!,
            type: InteractionType.event,
            detail: T.toString(),
          ),
        );
      }
      try {
        (subscription.callback as void Function(T))(event);
      } catch (e) {
        AirLogger.error('Error in subscriber ${subscription.id}', error: e);
      }
    }

    notifyListeners();
  }

  /// Emit a named signal with identity verification and rate limiting.
  void emitSignal(
    String signalName, {
    dynamic data,
    String? sourceModuleId,
    ModuleIdentityToken? identityToken,
  }) {
    final effectiveSourceId =
        sourceModuleId ?? identityToken?.moduleId ?? 'unknown';

    // Verify identity if token is provided
    if (identityToken != null && sourceModuleId != null) {
      if (!identityToken.verify(sourceModuleId)) {
        AirLogger.security(
          'Identity verification failed for signal emission',
          context: {'expected': sourceModuleId, 'got': identityToken.moduleId},
        );
        AirAudit().log(
          type: AuditType.securityViolation,
          action: 'identity_spoofing_attempt',
          moduleId: identityToken.moduleId,
          context: {'attemptedId': sourceModuleId, 'signal': signalName},
          severity: AuditSeverity.critical,
          success: false,
        );
        return;
      }
    }

    // Check rate limit
    final rateLimitKey = '$effectiveSourceId:signal:$signalName';
    if (!_checkRateLimit(rateLimitKey)) {
      AirAudit().log(
        type: AuditType.securityViolation,
        action: 'signal_rate_limit_exceeded',
        moduleId: effectiveSourceId,
        context: {'signal': signalName},
        severity: AuditSeverity.medium,
        success: false,
      );
      return;
    }

    // Check permission to emit
    if (!PermissionChecker().checkPermission(
      effectiveSourceId,
      Permission.eventEmit,
      resource: signalName,
    )) {
      return;
    }

    AirLogger.debug(
      'Emitting signal "$signalName"',
      context: {'source': effectiveSourceId},
    );

    // Verify module identity and log the interaction for auditing.
    AirAudit().log(
      type: AuditType.moduleInteraction,
      action: 'signal_emitted',
      moduleId: effectiveSourceId,
      context: {'signal': signalName, 'hasData': data != null},
    );

    // Add to history
    _signalHistory.add(
      SignalHistoryEntry(
        name: signalName,
        data: data,
        sourceModuleId: sourceModuleId,
      ),
    );
    if (_signalHistory.length > _maxHistorySize) {
      _signalHistory.removeAt(0);
    }

    final subs = _signalSubscriptions[signalName];
    if (subs == null || subs.isEmpty) {
      AirLogger.debug('No subscribers for signal "$signalName"');
      return;
    }

    // Create copy of active subscribers to iterate safely, then clean up cancelled/expired
    final activeSubs = subs
        .where((s) => !s.isCancelled && !s.isExpired)
        .toList();
    subs.removeWhere((s) => s.isCancelled || s.isExpired);

    for (final subscription in activeSubs) {
      if (subscription.subscriberModuleId != null) {
        // Record interaction. If source is unknown, we use the target itself to create a "bloom" effect
        SecureServiceRegistry().recordInteraction(
          ModuleInteraction(
            sourceId: sourceModuleId ?? subscription.subscriberModuleId!,
            targetId: subscription.subscriberModuleId!,
            type: InteractionType.event,
            detail: signalName,
          ),
        );
      }
      try {
        (subscription.callback as void Function(dynamic))(data);
      } catch (e) {
        AirLogger.error(
          'Error in signal subscriber ${subscription.id}',
          error: e,
        );
      }
    }

    notifyListeners();
  }

  /// Emit an event asynchronously (non-blocking)
  Future<void> emitAsync<T extends ModuleEvent>(T event) async {
    await Future.microtask(() => emit(event));
  }

  /// Cancel a specific subscription
  void cancel(EventSubscription subscription) {
    subscription.cancel();
    _subscriptions[subscription.eventType]?.remove(subscription);
    AirLogger.debug('Cancelled subscription ${subscription.id}');
  }

  /// Cancel all subscriptions from a module
  void cancelModuleSubscriptions(String moduleId) {
    int count = 0;
    for (final subs in _subscriptions.values) {
      subs.removeWhere((s) {
        if (s.subscriberModuleId == moduleId) {
          s.cancel();
          count++;
          return true;
        }
        return false;
      });
    }

    // Also clean up signal subscriptions
    for (final subs in _signalSubscriptions.values) {
      subs.removeWhere((s) {
        if (s.subscriberModuleId == moduleId) {
          s.cancel();
          count++;
          return true;
        }
        return false;
      });
    }
    AirLogger.debug(
      'Cancelled subscriptions for module',
      context: {'moduleId': moduleId, 'count': count},
    );
  }

  /// Get recent events of a specific type
  List<T> getRecentEvents<T extends ModuleEvent>({int limit = 10}) {
    return _eventHistory.whereType<T>().toList().reversed.take(limit).toList();
  }

  /// Get all event history
  List<ModuleEvent> get eventHistory => List.unmodifiable(_eventHistory);

  /// Get all signal history
  List<SignalHistoryEntry> get signalHistory =>
      List.unmodifiable(_signalHistory);

  /// Check if there are subscribers for an event type
  bool hasSubscribers<T extends ModuleEvent>() {
    final subs = _subscriptions[T];
    return subs != null && subs.any((s) => !s.isCancelled && !s.isExpired);
  }

  /// Get subscriber count for an event type
  int subscriberCount<T extends ModuleEvent>() {
    return _subscriptions[T]
            ?.where((s) => !s.isCancelled && !s.isExpired)
            .length ??
        0;
  }

  /// Clears all subscriptions and histories.
  ///
  /// This method is only available in debug or testing environments to prevent
  /// accidental data loss in production.
  @visibleForTesting
  void clearAll() {
    if (!kDebugMode) {
      AirLogger.warning('EventBus.clearAll() called in release mode - ignored');
      return;
    }

    for (final subs in _subscriptions.values) {
      for (final s in subs) {
        s.cancel();
      }
    }
    _subscriptions.clear();

    for (final subs in _signalSubscriptions.values) {
      for (final s in subs) {
        s.cancel();
      }
    }
    _signalSubscriptions.clear();

    _eventHistory.clear();
    _signalHistory.clear();
    _emitHistory.clear();
    _subscriptionIdCounter = 0;
  }

  /// Dispose resources
  @override
  void dispose() {
    _cleanupTimer?.cancel();
    clearAll();
    super.dispose();
  }
}

// ============ Common Event Types ============

/// Fired when a module is installed
class ModuleInstalledEvent extends ModuleEvent {
  final String installedModuleId;
  final String installedModuleName;
  final String version;

  ModuleInstalledEvent({
    required super.sourceModuleId,
    required this.installedModuleId,
    required this.installedModuleName,
    required this.version,
  });
}

/// Fired when a module is uninstalled
class ModuleUninstalledEvent extends ModuleEvent {
  final String uninstalledModuleId;

  ModuleUninstalledEvent({
    required super.sourceModuleId,
    required this.uninstalledModuleId,
  });
}

/// Fired when data changes in a module
class DataChangedEvent extends ModuleEvent {
  final String dataKey;
  final dynamic oldValue;
  final dynamic newValue;

  DataChangedEvent({
    required super.sourceModuleId,
    required this.dataKey,
    this.oldValue,
    this.newValue,
  });
}

/// Fired when a service is called
class ServiceCalledEvent extends ModuleEvent {
  final String serviceName;
  final String callerModuleId;
  final bool success;

  ServiceCalledEvent({
    required super.sourceModuleId,
    required this.serviceName,
    required this.callerModuleId,
    required this.success,
  });
}
