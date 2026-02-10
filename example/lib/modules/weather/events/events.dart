import 'package:air_framework/air_framework.dart';

/// Typed event for cross-module communication.
///
/// Demonstrates:
/// - Extending ModuleEvent for typed events
/// - EventBus integration for cross-module data sharing
class WeatherUpdatedEvent extends ModuleEvent {
  final String city;
  final double temperature;
  final String condition;
  final String icon;

  WeatherUpdatedEvent({
    required super.sourceModuleId,
    required this.city,
    required this.temperature,
    required this.condition,
    required this.icon,
  });
}
