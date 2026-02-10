import 'dart:ui';
import 'package:flutter/material.dart';
import 'tabs/modules_tab.dart';
import 'tabs/state_tab.dart';
import 'tabs/pulses_tab.dart';
import 'tabs/di_tab.dart';
import 'tabs/performance_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/air_graph_tab.dart';

/// Debug inspector widget for development
/// Shows real-time module and framework state
class ModuleDebugInspector extends StatefulWidget {
  const ModuleDebugInspector({super.key});

  @override
  State<ModuleDebugInspector> createState() => _ModuleDebugInspectorState();
}

class _ModuleDebugInspectorState extends State<ModuleDebugInspector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;
  bool _showContent = false;
  Offset _position = Offset.zero;
  bool _hasInitializedPosition = false;

  // Performance monitoring
  final List<int> _frameTimes = [];
  DateTime? _lastFrameTime;
  double _fps = 60;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _startPerformanceMonitoring();
  }

  void _startPerformanceMonitoring() {
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    if (!mounted) return;

    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMilliseconds;
      _frameTimes.add(frameTime);
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }

      if (_frameTimes.isNotEmpty) {
        final avgFrameTime =
            _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
        _fps = avgFrameTime > 0 ? 1000 / avgFrameTime : 60;
      }

      if (_showContent && _tabController.index == 4) {
        setState(() {});
      }
    }
    _lastFrameTime = now;
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedPosition) {
      final size = MediaQuery.of(context).size;
      _position = Offset(size.width - 80, size.height - 80);
      _hasInitializedPosition = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (_isExpanded) {
      setState(() {
        _showContent = false;
        _isExpanded = false;
      });
    } else {
      setState(() => _isExpanded = true);
      Future.delayed(const Duration(milliseconds: 320), () {
        if (mounted && _isExpanded) {
          setState(() => _showContent = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.7;
    final maxWidth = mediaQuery.size.width * 0.9;

    final double actualWidth = _isExpanded
        ? (mediaQuery.size.width < 500 ? maxWidth : 400)
        : 56;
    final double actualHeight = _isExpanded
        ? (maxHeight > 600 ? 600 : maxHeight)
        : 56;

    return Positioned(
      left: _position.dx.clamp(
        0,
        (mediaQuery.size.width - actualWidth).clamp(0, double.infinity),
      ),
      top: _position.dy.clamp(
        0,
        (mediaQuery.size.height - actualHeight).clamp(0, double.infinity),
      ),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          width: actualWidth,
          height: actualHeight,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(_isExpanded ? 24 : 28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isExpanded ? 24 : 28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: _isExpanded
                  ? (_showContent
                        ? Navigator(
                            onGenerateRoute: (_) => MaterialPageRoute(
                              builder: (context) => _buildExpandedContent(),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.cyanAccent,
                              ),
                            ),
                          ))
                  : _buildCollapsedButton(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(28),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.bolt, color: Colors.cyanAccent, size: 28),
              if (_fps < 50)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          // Custom Header
          _buildHeader(),

          // Custom Tabs
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.cyanAccent,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'GRAPH'),
                Tab(text: 'MODULES'),
                Tab(text: 'STATE'),
                Tab(text: 'PULSES'),
                Tab(text: 'DI'),
                Tab(text: 'PERF'),
                Tab(text: 'LOGS'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const AirGraphTab(),
                ModulesTab(onAction: _toggleExpanded),
                const StateTab(),
                const PulsesTab(),
                const DITab(),
                PerformanceTab(fps: _fps, frameTimes: _frameTimes),
                const LogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AIR DEVTOOLS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'v1.0.0 • ${_fps.toStringAsFixed(0)} FPS',
                style: TextStyle(
                  color: _fps > 55 ? Colors.greenAccent : Colors.orangeAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          _headerAction(Icons.refresh, () => setState(() {})),
          const SizedBox(width: 8),
          _headerAction(Icons.close, _toggleExpanded),
        ],
      ),
    );
  }

  Widget _headerAction(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70, size: 18),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      ),
    );
  }
}

/// Overlay wrapper that adds debug inspector to any screen
class DebugOverlay extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const DebugOverlay({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Stack(children: [child, const ModuleDebugInspector()]);
  }
}
