import 'package:air_state/air_state.dart';
import '../communication/event_bus.dart';
import '../security/secure_service_registry.dart';
import '../security/air_logger.dart';
import '../security/permissions.dart';

/// Adapter that connects Air State to the framework's security and event bus
class SecureAirDelegate implements AirDelegate {
  @override
  void log(
    String message, {
    Map<String, dynamic>? context,
    bool isError = false,
  }) {
    if (isError) {
      AirLogger.error(message, context: context);
    } else {
      AirLogger.debug(message, context: context);
    }
  }

  @override
  void recordInteraction(
    String sourceId,
    String targetId,
    String type,
    String detail,
  ) {
    InteractionType interactionType;
    switch (type) {
      case 'service':
        interactionType = InteractionType.service;
        break;
      case 'event':
        interactionType = InteractionType.event;
        break;
      case 'data':
      default:
        interactionType = InteractionType.data;
        break;
    }

    SecureServiceRegistry().recordInteraction(
      ModuleInteraction(
        sourceId: sourceId,
        targetId: targetId,
        type: interactionType,
        detail: detail,
      ),
    );
  }

  @override
  void pulse(String action, dynamic params, {String? sourceId}) {
    // EventBus().emitSignal already checks for Permission.eventEmit internally.
    EventBus().emitSignal(action, data: params, sourceModuleId: sourceId);
  }

  @override
  bool canAccess(String key, {String? sourceId}) {
    return PermissionChecker().checkPermission(
      sourceId ?? 'unknown',
      Permission.dataRead,
      resource: key,
    );
  }

  @override
  dynamic subscribe(
    String key,
    void Function(dynamic) callback, {
    String? sourceId,
  }) {
    String? effectiveSourceId = sourceId;

    // Fallback: If sourceId is missing, try to infer it from the key (e.g. 'counter.increment')
    // This allows internal module state controllers (like CounterState) to subscribe
    // to their own signals even if the identity isn't explicitly passed down yet.
    if (effectiveSourceId == null && key.contains('.')) {
      effectiveSourceId = key.split('.').first;
    }

    // Record data interaction for auditing
    if (effectiveSourceId != null) {
      // Try to find the owner module from the key (e.g., 'counter.count' -> 'counter')
      final dotIndex = key.indexOf('.');
      final targetModuleId = dotIndex != -1
          ? key.substring(0, dotIndex)
          : 'unknown';

      // Only record if it's an interaction between different modules
      if (effectiveSourceId != targetModuleId) {
        recordInteraction(effectiveSourceId, targetModuleId, 'data', key);
      }
    }

    // Return the subscription via EventBus
    return EventBus().onSignal(
      key,
      callback,
      subscriberModuleId: effectiveSourceId,
    );
  }
}
