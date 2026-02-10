import 'package:flutter/material.dart';

class PerformanceTab extends StatelessWidget {
  final double fps;
  final List<int> frameTimes;

  const PerformanceTab({
    super.key,
    required this.fps,
    required this.frameTimes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _perfStat(
                'Current FPS',
                fps.toStringAsFixed(1),
                fps > 55 ? Colors.greenAccent : Colors.redAccent,
              ),
              _perfStat(
                'Frames',
                frameTimes.length.toString(),
                Colors.blueAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'FRAME TIMES (ms)',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: _PerfPainter(frameTimes),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _PerfPainter extends CustomPainter {
  final List<int> frameTimes;
  _PerfPainter(this.frameTimes);

  @override
  void paint(Canvas canvas, Size size) {
    if (frameTimes.isEmpty) return;

    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxFrame = 33.0; // Max 33ms (30fps) for scale

    for (int i = 0; i < frameTimes.length; i++) {
      final x = (size.width / 59) * i;
      final y =
          size.height -
          (frameTimes[i] / maxFrame * size.height).clamp(0, size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw 16ms line (60fps)
    final targetY = size.height - (16.0 / maxFrame * size.height);
    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      Paint()
        ..color = Colors.greenAccent.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PerfPainter oldDelegate) => true;
}
