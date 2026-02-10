import 'package:flutter/material.dart';

/// Performance monitor widget for development
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final List<int> _frameTimes = [];
  DateTime? _lastFrameTime;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback(_onFrame);
    }
  }

  void _onFrame(Duration timestamp) {
    if (!mounted || !widget.enabled) return;

    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMilliseconds;
      _frameTimes.add(frameTime);
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
      if (_showOverlay) {
        setState(() {});
      }
    }
    _lastFrameTime = now;

    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  double get _averageFps {
    if (_frameTimes.isEmpty) return 60;
    final avgFrameTime =
        _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    return avgFrameTime > 0 ? 1000 / avgFrameTime : 60;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 16,
          bottom: 16,
          child: GestureDetector(
            onTap: () => setState(() => _showOverlay = !_showOverlay),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getFpsColor().withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_averageFps.toStringAsFixed(0)} FPS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showOverlay)
          Positioned(
            left: 16,
            bottom: 60,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStat('Avg FPS', _averageFps.toStringAsFixed(1)),
                  _buildStat('Frame samples', _frameTimes.length.toString()),
                  if (_frameTimes.isNotEmpty) ...[
                    _buildStat(
                      'Min frame',
                      '${_frameTimes.reduce((a, b) => a < b ? a : b)} ms',
                    ),
                    _buildStat(
                      'Max frame',
                      '${_frameTimes.reduce((a, b) => a > b ? a : b)} ms',
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Mini frame graph
                  SizedBox(
                    height: 40,
                    child: CustomPaint(
                      size: const Size(176, 40),
                      painter: _FrameGraphPainter(_frameTimes),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _getFpsColor() {
    if (_averageFps >= 55) return Colors.green;
    if (_averageFps >= 30) return Colors.orange;
    return Colors.red;
  }
}

class _FrameGraphPainter extends CustomPainter {
  final List<int> frameTimes;

  _FrameGraphPainter(this.frameTimes);

  @override
  void paint(Canvas canvas, Size size) {
    if (frameTimes.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final maxFrame = frameTimes.reduce((a, b) => a > b ? a : b).toDouble();
    final targetLine = 16.67; // 60 FPS target

    // Draw target line
    final targetY =
        size.height -
        (targetLine / maxFrame * size.height).clamp(0, size.height);
    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      Paint()
        ..color = Colors.green.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // Draw frame times
    if (frameTimes.length < 2) return;

    final path = Path();
    for (int i = 0; i < frameTimes.length; i++) {
      final x = i / (frameTimes.length - 1) * size.width;
      final y = size.height - (frameTimes[i] / maxFrame * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    paint.color = Colors.cyan;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FrameGraphPainter oldDelegate) {
    return oldDelegate.frameTimes != frameTimes;
  }
}
