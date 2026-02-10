// ignore_for_file: unused_field
import 'package:air_framework/air_framework.dart';

import '../../events/events.dart';
import '../../models/weather.dart';
import '../../services/weather_service.dart';

part 'state.air.g.dart';

/// Weather state management with EventBus integration.
///
/// Demonstrates:
/// - @GenerateState for automatic code generation
/// - Async operations with loading/error states
/// - Cross-module communication via EventBus
/// - Null-safe state handling
@GenerateState('weather')
class WeatherState extends _WeatherState {
  // ═══════════════════════════════════════════════════════════════════════════
  // STATE FLOWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current weather data (null when not loaded)
  final Weather? _currentWeather = null;

  /// Currently selected city
  final String _city = 'New York';

  /// Loading state
  final bool _isLoading = false;

  /// Error message if fetch fails
  final String? _error = null;

  /// Whether auto-refresh is enabled
  final bool _autoRefresh = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    // Fetch initial weather on startup
    fetchWeather();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PULSES (Actions)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch weather for the current city
  @override
  Future<void> fetchWeather() async {
    isLoading = true;
    error = null;

    try {
      final service = AirDI().get<WeatherService>();
      final weather = await service.getWeather(city);

      currentWeather = weather;

      // Emit event for cross-module communication
      // Other modules (like Dashboard) can listen to this
      EventBus().emit(
        WeatherUpdatedEvent(
          sourceModuleId: 'weather',
          city: weather.city,
          temperature: weather.temperature,
          condition: weather.condition,
          icon: weather.icon,
        ),
      );
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
    }
  }

  /// Change the selected city and fetch new weather
  @override
  Future<void> changeCity(String newCity) async {
    if (newCity == city) return;

    city = newCity;
    await fetchWeather();
  }

  /// Toggle auto-refresh setting
  @override
  void toggleAutoRefresh() {
    autoRefresh = !autoRefresh;
  }

  /// Clear any error
  @override
  void clearError() {
    error = null;
  }

  /// Refresh weather data
  @override
  Future<void> refresh() async {
    await fetchWeather();
  }
}
