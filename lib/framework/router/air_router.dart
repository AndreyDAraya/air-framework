import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

export 'package:go_router/go_router.dart';
import '../../core/module_manager.dart';
import 'air_route.dart';

class AirRouter {
  static final AirRouter _instance = AirRouter._internal();
  factory AirRouter() => _instance;
  AirRouter._internal();

  late final GoRouter _router;
  bool _initialized = false;
  String? _initialLocation;

  set initialLocation(String location) {
    if (_initialized) {
      debugPrint(
        'Warning: AirRouter is already initialized. Setting initialLocation to $location will have no effect.',
      );
      return;
    }
    _initialLocation = location;
  }

  GoRouter get router {
    if (!_initialized) {
      _initialize();
    }
    return _router;
  }

  void _initialize() {
    final List<RouteBase> routes = [];

    // Transform AirRoutes to GoRoutes
    // We access ModuleManager directly here, assuming modules are registered
    final moduleManager = ModuleManager();
    final allRoutes = moduleManager.getAirRoutes();

    if (allRoutes.isEmpty) {
      debugPrint(
        'Warning: AirRouter initialized with no routes. '
        'Make sure to register modules before accessing router.',
      );
    }

    for (final route in allRoutes) {
      routes.add(_convertRoute(route));
    }

    _router = GoRouter(
      initialLocation: _initialLocation ?? '/',
      routes: routes,
      debugLogDiagnostics: true,
    );
    _initialized = true;
  }

  RouteBase _convertRoute(AirRoute route) {
    final childRoutes = route.routes.map((r) => _convertRoute(r)).toList();

    if (route.isShellRoute) {
      return ShellRoute(
        builder: (context, state, child) => route.builder(context, state),
        routes: childRoutes.cast<RouteBase>(),
      );
    }

    return GoRoute(
      path: route.path,
      builder: (context, state) => route.builder(context, state),
      routes: childRoutes.cast<RouteBase>(),
    );
  }
}
