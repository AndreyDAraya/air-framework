import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import '../../../dashboard/ui/views/dashboard_page.dart';
import '../../../notes/ui/views/notes_list_page.dart';
import '../../../weather/ui/views/weather_page.dart';

/// Shell page with bottom navigation.
///
/// Demonstrates:
/// - Persistent navigation layout with go_router
/// - Bottom navigation bar
/// - Tab-based navigation
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current location to determine selected tab
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      body: _getBody(selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Weather',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.contains('/notes')) return 1;
    if (location.contains('/weather')) return 2;
    return 0; // Default to dashboard
  }

  Widget _getBody(int index) {
    switch (index) {
      case 1:
        return const NotesListPage();
      case 2:
        return const WeatherPage();
      default:
        return const DashboardPage();
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/shell');
        break;
      case 1:
        context.go('/shell/notes');
        break;
      case 2:
        context.go('/shell/weather');
        break;
    }
  }
}
