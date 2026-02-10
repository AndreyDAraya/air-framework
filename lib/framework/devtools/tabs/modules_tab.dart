import 'package:flutter/material.dart';
import 'package:air_framework/core/module_manager.dart';
import 'package:air_framework/framework/router/air_router.dart';
import '../widgets/shared_widgets.dart';

class ModulesTab extends StatelessWidget {
  final VoidCallback? onAction;

  const ModulesTab({super.key, this.onAction});

  @override
  Widget build(BuildContext context) {
    final modules = ModuleManager().modules;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            leading: Icon(module.icon, color: module.color, size: 24),
            title: Text(
              module.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${module.id} • v${module.version}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Colors.white12),
                    detailRow('Initial Route', module.initialRoute),
                    const SizedBox(height: 8),
                    const Text(
                      'Routes',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...module.routes.map((route) => _routeItem(route.path)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _routeItem(String path) {
    // Detect routes with path parameters (e.g., :id or {id})
    final hasParams = path.contains(':') || path.contains('{');

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.link,
            color: hasParams ? Colors.orange : Colors.cyanAccent,
            size: 12,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path,
              style: TextStyle(
                color: hasParams ? Colors.white54 : Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
          // Show PARAM label for routes requiring parameters instead of GO button
          if (hasParams)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'PARAM',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            InkWell(
              onTap: () {
                AirRouter().router.go(path);
                onAction?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'GO',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
