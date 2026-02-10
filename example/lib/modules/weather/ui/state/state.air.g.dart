// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'state.dart';

// **************************************************************************
// AirStateGenerator
// **************************************************************************

/// Pulses for the Weather module
class WeatherPulses {
  WeatherPulses._();

  /// Pulse: fetchWeather
  static const fetchWeather = AirPulse<void>('weather.fetchWeather');

  /// Pulse: changeCity
  static const changeCity = AirPulse<String>('weather.changeCity');

  /// Pulse: toggleAutoRefresh
  static const toggleAutoRefresh = AirPulse<void>('weather.toggleAutoRefresh');

  /// Pulse: clearError
  static const clearError = AirPulse<void>('weather.clearError');

  /// Pulse: refresh
  static const refresh = AirPulse<void>('weather.refresh');
}

/// Flows for the Weather module
class WeatherFlows {
  WeatherFlows._();

  /// Flow: currentWeather
  static const currentWeather =
      SimpleStateKey<Weather?>('weather.currentWeather', defaultValue: null);

  /// Flow: city
  static const city = SimpleStateKey<String>('weather.city', defaultValue: '');

  /// Flow: isLoading
  static const isLoading =
      SimpleStateKey<bool>('weather.isLoading', defaultValue: false);

  /// Flow: error
  static const error =
      SimpleStateKey<String?>('weather.error', defaultValue: '');

  /// Flow: autoRefresh
  static const autoRefresh =
      SimpleStateKey<bool>('weather.autoRefresh', defaultValue: false);
}

/// Base class for WeatherState
abstract class _WeatherState extends AirState {
  _WeatherState() : super(moduleId: 'weather');

  /// Handle fetchWeather pulse
  Future<void> fetchWeather();

  /// Handle changeCity pulse
  Future<void> changeCity(String newCity);

  /// Handle toggleAutoRefresh pulse
  void toggleAutoRefresh();

  /// Handle clearError pulse
  void clearError();

  /// Handle refresh pulse
  Future<void> refresh();

  /// Get currentWeather value
  Weather? get currentWeather => Air().typedGet(WeatherFlows.currentWeather);

  /// Set currentWeather value
  set currentWeather(Weather? value) => Air()
      .typedFlow(WeatherFlows.currentWeather, value, sourceModuleId: moduleId);

  /// Get city value
  String get city => Air().typedGet(WeatherFlows.city);

  /// Set city value
  set city(String value) =>
      Air().typedFlow(WeatherFlows.city, value, sourceModuleId: moduleId);

  /// Get isLoading value
  bool get isLoading => Air().typedGet(WeatherFlows.isLoading);

  /// Set isLoading value
  set isLoading(bool value) =>
      Air().typedFlow(WeatherFlows.isLoading, value, sourceModuleId: moduleId);

  /// Get error value
  String? get error => Air().typedGet(WeatherFlows.error);

  /// Set error value
  set error(String? value) =>
      Air().typedFlow(WeatherFlows.error, value, sourceModuleId: moduleId);

  /// Get autoRefresh value
  bool get autoRefresh => Air().typedGet(WeatherFlows.autoRefresh);

  /// Set autoRefresh value
  set autoRefresh(bool value) => Air()
      .typedFlow(WeatherFlows.autoRefresh, value, sourceModuleId: moduleId);

  @override
  void onPulses() {
    on(WeatherPulses.fetchWeather, (_, {onSuccess, onError}) async {
      try {
        await fetchWeather();
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(WeatherPulses.changeCity, (value, {onSuccess, onError}) async {
      try {
        await changeCity(value);
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(WeatherPulses.toggleAutoRefresh, (_, {onSuccess, onError}) async {
      try {
        toggleAutoRefresh();
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(WeatherPulses.clearError, (_, {onSuccess, onError}) async {
      try {
        clearError();
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(WeatherPulses.refresh, (_, {onSuccess, onError}) async {
      try {
        await refresh();
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
  }
}
