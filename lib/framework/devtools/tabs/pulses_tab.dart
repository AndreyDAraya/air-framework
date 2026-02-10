import 'package:flutter/material.dart';
import '../../communication/event_bus.dart';
import '../widgets/shared_widgets.dart';

class PulsesTab extends StatelessWidget {
  const PulsesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final history = EventBus().signalHistory;

    if (history.isEmpty) {
      return emptyState(Icons.history, 'No pulses recorded');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[history.length - 1 - index];
        return buildDebugCard(
          icon: Icons.bolt,
          iconColor: Colors.amberAccent,
          title: entry.name,
          subtitle: 'From: ${entry.sourceModuleId ?? 'Global'}',
          trailing: formatTime(entry.timestamp),
          extra: entry.data != null ? 'Data: ${entry.data}' : null,
        );
      },
    );
  }
}
