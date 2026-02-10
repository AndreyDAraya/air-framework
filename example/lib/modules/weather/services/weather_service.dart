import 'dart:math';

import '../models/weather.dart';

/// Weather service that provides weather data.
///
/// This is a mock implementation for demonstration purposes.
/// In a real app, this would call an actual weather API.
///
/// Demonstrates:
/// - Async service pattern
/// - Simulated network delay
/// - Mock data generation
class WeatherService {
  final Random _random = Random();

  /// List of possible weather conditions with icons
  static const List<Map<String, String>> _conditions = [
    {'condition': 'Sunny', 'icon': '☀️'},
    {'condition': 'Partly Cloudy', 'icon': '⛅'},
    {'condition': 'Cloudy', 'icon': '☁️'},
    {'condition': 'Rainy', 'icon': '🌧️'},
    {'condition': 'Stormy', 'icon': '⛈️'},
    {'condition': 'Snowy', 'icon': '🌨️'},
    {'condition': 'Windy', 'icon': '💨'},
    {'condition': 'Foggy', 'icon': '🌫️'},
  ];

  /// Temperature ranges by city (for realistic mock data)
  static const Map<String, List<double>> _cityTempRanges = {
    'New York': [5, 28],
    'London': [8, 22],
    'Tokyo': [10, 32],
    'Paris': [6, 26],
    'Sydney': [15, 35],
    'Dubai': [22, 45],
    'Singapore': [25, 34],
    'Berlin': [2, 25],
    'Toronto': [-5, 28],
    'Mumbai': [22, 38],
  };

  /// Fetch weather for a city (mock implementation)
  Future<Weather> getWeather(String city) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 800 + _random.nextInt(700)));

    // Randomly fail sometimes (10% chance) to demonstrate error handling
    if (_random.nextDouble() < 0.1) {
      throw Exception('Network error: Unable to fetch weather data');
    }

    // Get temperature range for city
    final tempRange = _cityTempRanges[city] ?? [10, 30];
    final temperature =
        tempRange[0] + _random.nextDouble() * (tempRange[1] - tempRange[0]);

    // Random condition
    final conditionData = _conditions[_random.nextInt(_conditions.length)];

    return Weather(
      city: city,
      temperature: double.parse(temperature.toStringAsFixed(1)),
      condition: conditionData['condition']!,
      icon: conditionData['icon']!,
      humidity: 40 + _random.nextInt(50), // 40-90%
      windSpeed: double.parse((_random.nextDouble() * 30).toStringAsFixed(1)),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get weather for multiple cities
  Future<List<Weather>> getWeatherForCities(List<String> cities) async {
    final results = <Weather>[];
    for (final city in cities) {
      try {
        final weather = await getWeather(city);
        results.add(weather);
      } catch (_) {
        // Skip failed cities
      }
    }
    return results;
  }
}
