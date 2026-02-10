import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A wrapper for declaring routes in Air Framework
class AirRoute {
  final String path;

  /// Builder function that receives context and GoRouterState for type-safe access to route parameters
  final Widget Function(BuildContext context, GoRouterState state) builder;
  final List<AirRoute> routes;
  final bool isShellRoute;

  AirRoute({
    required this.path,
    required this.builder,
    this.routes = const [],
    this.isShellRoute = false,
  });
}
