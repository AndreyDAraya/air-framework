import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import '../../models/weather.dart';
import '../state/state.dart';

/// Weather page demonstrating async state and error handling.
///
/// Shows:
/// - AirView with loading/error/success states
/// - City selector dropdown
/// - Pull-to-refresh
/// - Weather card with animations
class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => WeatherPulses.refresh.pulse(null),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          WeatherPulses.refresh.pulse(null);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // City selector
              _buildCitySelector(context),
              const SizedBox(height: 24),

              // Weather display
              AirView((context) {
                // Loading state
                if (WeatherFlows.isLoading.value) {
                  return const _WeatherLoadingCard();
                }

                // Error state
                final error = WeatherFlows.error.value;
                if (error != null) {
                  return _WeatherErrorCard(
                    error: error,
                    onRetry: () => WeatherPulses.clearError.pulse(null),
                  );
                }

                // Success state
                final weather = WeatherFlows.currentWeather.value;
                if (weather == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            const Text('No weather data'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  WeatherPulses.fetchWeather.pulse(null),
                              child: const Text('Load Weather'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return _WeatherCard(weather: weather);
              }),

              const SizedBox(height: 24),

              // Info section
              _buildInfoSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCitySelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select City',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 12),
            AirView((context) {
              final currentCity = WeatherFlows.city.value;

              return DropdownButtonFormField<String>(
                initialValue: currentCity,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_city),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                items: WeatherCities.available.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (city) {
                  if (city != null) {
                    WeatherPulses.changeCity.pulse(city);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About This Demo',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This module demonstrates:\n'
              '• Async data fetching with loading states\n'
              '• Error handling and retry logic\n'
              '• EventBus for cross-module communication\n'
              '• Service layer pattern with mock API',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Weather card showing current conditions
class _WeatherCard extends StatelessWidget {
  final Weather weather;

  const _WeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Weather icon
            Text(weather.icon, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),

            // Temperature
            Text(
              '${weather.temperature.round()}°C',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),

            // Condition
            Text(
              weather.condition,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),

            // City
            Text(
              weather.city,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 24),

            // Details row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DetailItem(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '${weather.humidity}%',
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: colorScheme.outlineVariant,
                ),
                _DetailItem(
                  icon: Icons.air,
                  label: 'Wind',
                  value: '${weather.windSpeed} km/h',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Last updated
            Text(
              'Updated: ${_formatTime(weather.lastUpdated)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Detail item widget
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Loading card
class _WeatherLoadingCard extends StatelessWidget {
  const _WeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading weather...'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error card
class _WeatherErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _WeatherErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load weather',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: colorScheme.onErrorContainer),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                onRetry();
                WeatherPulses.fetchWeather.pulse(null);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
