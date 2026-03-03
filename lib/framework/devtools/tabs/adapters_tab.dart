import 'package:flutter/material.dart';
import '../../../core/adapter_manager.dart';
import '../../../core/air_adapter.dart';
import '../widgets/shared_widgets.dart';

/// DevTools tab that displays all registered Air Adapters.
///
/// Shows adapter ID, name, version, and lifecycle state with visual indicators.
class AdaptersTab extends StatelessWidget {
  const AdaptersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final adapters = AdapterManager().adapters;

    if (adapters.isEmpty) {
      return emptyState(Icons.extension_off, 'No adapters registered');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: adapters.length,
      itemBuilder: (context, index) {
        final adapter = adapters[index];
        return buildDebugCard(
          icon: _iconForState(adapter.state),
          iconColor: _colorForState(adapter.state),
          title: '${adapter.name} (${adapter.id})',
          subtitle: 'v${adapter.version}',
          trailing: adapter.state.name,
        );
      },
    );
  }

  IconData _iconForState(AdapterLifecycleState state) {
    return switch (state) {
      AdapterLifecycleState.initialized => Icons.power,
      AdapterLifecycleState.initializing => Icons.hourglass_top,
      AdapterLifecycleState.disposed => Icons.power_off,
      _ => Icons.power_settings_new,
    };
  }

  Color _colorForState(AdapterLifecycleState state) {
    return switch (state) {
      AdapterLifecycleState.initialized => Colors.greenAccent,
      AdapterLifecycleState.initializing => Colors.orangeAccent,
      AdapterLifecycleState.disposed => Colors.redAccent,
      _ => Colors.white38,
    };
  }
}
