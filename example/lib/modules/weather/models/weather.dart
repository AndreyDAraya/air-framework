/// Weather data model
///
/// Represents current weather conditions for a city.
class Weather {
  final String city;
  final double temperature;
  final String condition;
  final String icon;
  final int humidity;
  final double windSpeed;
  final DateTime lastUpdated;

  Weather({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.lastUpdated,
  });

  /// Create from JSON (for API responses)
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      city: json['city'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      condition: json['condition'] as String,
      icon: json['icon'] as String,
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'temperature': temperature,
      'condition': condition,
      'icon': icon,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  @override
  String toString() => 'Weather($city, $temperature°C, $condition)';
}

/// Predefined list of available cities
class WeatherCities {
  static const List<String> available = [
    "",
    'New York',
    'London',
    'Tokyo',
    'Paris',
    'Sydney',
    'Dubai',
    'Singapore',
    'Berlin',
    'Toronto',
    'Mumbai',
  ];
}
