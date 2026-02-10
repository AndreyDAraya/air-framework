import 'package:flutter/material.dart';
import '../../di/di.dart';
import '../widgets/shared_widgets.dart';

class DITab extends StatelessWidget {
  const DITab({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AirDI().debugRegisteredTypes;

    if (services.isEmpty) {
      return emptyState(Icons.extension_off, 'No services');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return buildDebugCard(
          icon: Icons.extension,
          iconColor: Colors.tealAccent,
          title: services[index],
          trailing: 'Active',
        );
      },
    );
  }
}
