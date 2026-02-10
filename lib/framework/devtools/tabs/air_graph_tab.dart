import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:air_framework/core/app_module.dart';
import 'package:air_framework/core/module_manager.dart';
import '../../security/secure_service_registry.dart';
import '../widgets/shared_widgets.dart';

class AirGraphTab extends StatefulWidget {
  const AirGraphTab({super.key});

  @override
  State<AirGraphTab> createState() => _AirGraphTabState();
}

class _AirGraphTabState extends State<AirGraphTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SecureServiceRegistry(), _pulseController]),
      builder: (context, _) {
        final modules = ModuleManager().modules;
        final interactions = SecureServiceRegistry().interactions;

        if (modules.isEmpty) {
          return emptyState(Icons.hub, 'No modules to visualize');
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'LIVE MODULE TRAFFIC',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ClipRect(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _GraphPainter(
                      modules: modules,
                      interactions: interactions,
                      relationships: SecureServiceRegistry().relationships,
                      pulseValue: _pulseController.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Service', Colors.cyanAccent),
        const SizedBox(width: 16),
        _legendItem('Event', Colors.purpleAccent),
        const SizedBox(width: 16),
        _legendItem('Data', Colors.orangeAccent),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<AppModule> modules;
  final List<ModuleInteraction> interactions;
  final Set<String> relationships;
  final double pulseValue;

  _GraphPainter({
    required this.modules,
    required this.interactions,
    required this.relationships,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.8;

    // Draw background grid
    _drawGrid(canvas, size);

    final nodePositions = <String, Offset>{};

    // Calculate node positions (Radial)
    for (var i = 0; i < modules.length; i++) {
      final angle = (2 * math.pi * i) / modules.length;
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      nodePositions[modules[i].id] = pos;
    }

    // Paint Persistent Relationships (discovered links)
    for (final rel in relationships) {
      final parts = rel.split('->');
      if (parts.length != 2) continue;
      final start = nodePositions[parts[0]];
      final end = nodePositions[parts[1]];
      if (start == null || end == null) continue;

      _drawDirectionalLink(
        canvas,
        start,
        end,
        Colors.white.withValues(alpha: 0.1),
        isDashed: true,
      );
    }

    // Paint Active Interactions (Pulses)
    final now = DateTime.now();
    for (final inter in interactions) {
      final start = nodePositions[inter.sourceId];
      final end = nodePositions[inter.targetId];

      if (start == null || end == null) continue;

      final age = now.difference(inter.timestamp).inMilliseconds;
      if (age > 2000) continue; // Only show recent hits

      final opacity = (1.0 - (age / 2000.0)).clamp(0.0, 1.0);
      final color = _getColor(inter.type).withValues(alpha: opacity);

      _drawDirectionalLink(
        canvas,
        start,
        end,
        color,
        strokeWidth: 2.5,
        drawArrow: true,
      );

      // Draw pulse particle
      if (age < 1500) {
        final t = (age / 1500.0);
        if (start == end) {
          // Self-loop pulse: just bloom the node
          final bloomRadius = 22 + (20 * math.sin(t * math.pi));
          canvas.drawCircle(
            start,
            bloomRadius,
            Paint()
              ..color = color.withValues(alpha: (1.0 - t) * 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
        } else {
          final path = _getCurvePath(start, end);
          final metrics = path.computeMetrics().first;
          final pos = metrics.getTangentForOffset(metrics.length * t)?.position;
          if (pos != null) {
            canvas.drawCircle(
              pos,
              4,
              Paint()
                ..color = color
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
            );
            canvas.drawCircle(pos, 2, Paint()..color = Colors.white);
          }
        }
      }
    }

    // Paint Nodes
    for (final module in modules) {
      final pos = nodePositions[module.id]!;
      _drawModuleNode(canvas, pos, module);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  void _drawModuleNode(Canvas canvas, Offset pos, AppModule module) {
    // Outer Glow
    final glowPaint = Paint()
      ..color = module.color.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(pos, 28, glowPaint);

    // Border
    final borderPaint = Paint()
      ..color = module.color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(pos, 22, borderPaint);

    // Fill
    canvas.drawCircle(pos, 22, Paint()..color = const Color(0xFF0A0A0A));

    // Icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(module.icon.codePoint),
        style: TextStyle(
          color: module.color,
          fontSize: 20,
          fontFamily: module.icon.fontFamily,
          package: module.icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      pos - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );

    // Label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: module.id,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, pos + Offset(-labelPainter.width / 2, 30));
  }

  void _drawDirectionalLink(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    double strokeWidth = 1.0,
    bool isDashed = false,
    bool drawArrow = false,
  }) {
    if (start == end) {
      // Draw a small loop for self-interaction
      final rect = Rect.fromCenter(
        center: start + const Offset(0, -25),
        width: 20,
        height: 20,
      );
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }

    final path = _getCurvePath(start, end);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (isDashed) {
      final metrics = path.computeMetrics().first;
      double distance = 0;
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      while (distance < metrics.length) {
        canvas.drawPath(
          metrics.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    } else {
      canvas.drawPath(path, paint);
    }

    if (drawArrow) {
      final metrics = path.computeMetrics().first;
      // Arrow pointing at target, slightly before the node
      final tangent = metrics.getTangentForOffset(metrics.length - 25);
      if (tangent != null) {
        final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);
        const arrowSize = 8.0;
        final arrowPath = Path();
        arrowPath.moveTo(
          tangent.position.dx + math.cos(angle) * arrowSize,
          tangent.position.dy + math.sin(angle) * arrowSize,
        );
        arrowPath.lineTo(
          tangent.position.dx + math.cos(angle + 2.5) * arrowSize,
          tangent.position.dy + math.sin(angle + 2.5) * arrowSize,
        );
        arrowPath.lineTo(
          tangent.position.dx + math.cos(angle - 2.5) * arrowSize,
          tangent.position.dy + math.sin(angle - 2.5) * arrowSize,
        );
        arrowPath.close();
        canvas.drawPath(arrowPath, Paint()..color = color);
      }
    }
  }

  Path _getCurvePath(Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    final midPoint = (start + end) / 2;
    final normal = Offset(start.dy - end.dy, end.dx - start.dx).unit * 40;
    final control = midPoint + normal;
    path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    return path;
  }

  Color _getColor(InteractionType type) {
    switch (type) {
      case InteractionType.service:
        return Colors.cyanAccent;
      case InteractionType.event:
        return Colors.purpleAccent;
      case InteractionType.data:
        return Colors.orangeAccent;
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    // Only repaint when data actually changes to optimize performance
    return modules.length != oldDelegate.modules.length ||
        interactions.length != oldDelegate.interactions.length ||
        relationships.length != oldDelegate.relationships.length ||
        pulseValue != oldDelegate.pulseValue;
  }
}

extension OffsetExt on Offset {
  Offset get unit {
    final double l = distance;
    if (l == 0) return Offset.zero;
    return this / l;
  }
}
