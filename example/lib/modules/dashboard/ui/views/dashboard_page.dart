import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import '../../../notes/ui/state/state.dart' as notes;
import '../../../weather/ui/state/state.dart' as weather;
import '../state/state.dart';

/// Dashboard page demonstrating cross-module state consumption.
///
/// Shows:
/// - AirView consuming state from multiple modules
/// - Cross-module data aggregation
/// - Quick action navigation
/// - Composite UI patterns
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AirView((context) {
          // Could use Dashboard state for user name
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.air, size: 28),
              const SizedBox(width: 8),
              Text(
                'Hello, ${DashboardFlows.userName.value}!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          );
        }),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weather widget - consuming Weather module state
            _buildWeatherWidget(context),
            const SizedBox(height: 16),

            // Notes summary - consuming Notes module state
            _buildNotesSummary(context),
            const SizedBox(height: 16),

            // Quick actions
            _buildQuickActions(context),
            const SizedBox(height: 16),

            // Tips section
            AirView((context) {
              if (DashboardFlows.tipsDismissed.value) {
                return const SizedBox.shrink();
              }
              return _buildTipsCard(context);
            }),
          ],
        ),
      ),
    );
  }

  /// Weather widget showing current conditions
  Widget _buildWeatherWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/shell/weather'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AirView((context) {
            final isLoading = weather.WeatherFlows.isLoading.value;
            final currentWeather = weather.WeatherFlows.currentWeather.value;
            final error = weather.WeatherFlows.error.value;

            if (isLoading) {
              return const Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 16),
                  Text('Loading weather...'),
                ],
              );
            }

            if (error != null || currentWeather == null) {
              return Row(
                children: [
                  Icon(Icons.cloud_off, color: colorScheme.outline, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Weather unavailable'),
                        Text(
                          'Tap to retry',
                          style: TextStyle(
                            color: colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colorScheme.outline),
                ],
              );
            }

            return Row(
              children: [
                // Weather icon
                Text(currentWeather.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),

                // Weather info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${currentWeather.temperature.round()}°C',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentWeather.condition,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      Text(
                        currentWeather.city,
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ],
                  ),
                ),

                Icon(Icons.chevron_right, color: colorScheme.outline),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Notes summary card
  Widget _buildNotesSummary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/shell/notes'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AirView((context) {
            final notesState = AirDI().get<notes.NotesState>();
            final totalNotes = notesState.totalCount;
            final pinnedNotes = notesState.pinnedCount;

            return Row(
              children: [
                // Notes icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.note, color: colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),

                // Notes count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalNotes Notes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (pinnedNotes > 0)
                        Text(
                          '$pinnedNotes pinned',
                          style: TextStyle(color: colorScheme.outline),
                        )
                      else
                        Text(
                          totalNotes == 0
                              ? 'Tap to create your first note'
                              : 'View all your notes',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                    ],
                  ),
                ),

                Icon(Icons.chevron_right, color: colorScheme.outline),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Quick actions section
  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickActionButton(
                  icon: Icons.add_circle,
                  label: 'New Note',
                  color: colorScheme.primary,
                  onTap: () {
                    DashboardPulses.incrementQuickActions.pulse(null);
                    context.push('/notes/new');
                  },
                ),
                _QuickActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh',
                  color: colorScheme.secondary,
                  onTap: () {
                    DashboardPulses.incrementQuickActions.pulse(null);
                    notes.NotesPulses.loadNotes.pulse(null);
                    weather.WeatherPulses.refresh.pulse(null);
                  },
                ),
                _QuickActionButton(
                  icon: Icons.search,
                  label: 'Search',
                  color: colorScheme.tertiary,
                  onTap: () {
                    DashboardPulses.incrementQuickActions.pulse(null);
                    context.go('/shell/notes');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tips card
  Widget _buildTipsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Air Framework Tips',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  onPressed: () => DashboardPulses.dismissTips.pulse(null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• This dashboard consumes state from Notes and Weather modules\n'
              '• Use AirView to reactively display data from any module\n'
              '• Swipe down on any page to enable the debug inspector',
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action button widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
