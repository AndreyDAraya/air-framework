import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import 'adapters/dio/dio_adapter.dart';
import 'app.dart';
import 'modules/dashboard/dashboard_module.dart';
import 'modules/notes/notes_module.dart';
import 'modules/shell/shell_module.dart';
import 'modules/users/users_module.dart';
import 'modules/weather/weather_module.dart';

/// Entry point for AirNotes Pro - Air Framework Example App
///
/// This example demonstrates:
/// - **Adapter pattern** with DioAdapter for HTTP calls
/// - Module registration and lifecycle (onBind/onInit)
/// - Dependency injection with AirDI
/// - Reactive state management with @GenerateState
/// - Cross-module communication via EventBus
/// - Routing with AirRouter
/// - DevTools integration
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PermissionChecker().enableStrictDebugMode(); // violations tiran excepción

  // Configure Air State for reactive state management
  configureAirState();

  // ═══════════════════════════════════════════════════
  // 1. Register Adapters (infrastructure services)
  //    Adapters are registered BEFORE modules so that
  //    modules can depend on adapter-provided services.
  // ═══════════════════════════════════════════════════
  final adapters = AdapterManager();

  await adapters.register(
    DioAdapter(baseUrl: 'https://jsonplaceholder.typicode.com'),
  );

  // ═══════════════════════════════════════════════════
  // 2. Register Modules (feature modules)
  //    Order matters: register dependencies first
  // ═══════════════════════════════════════════════════
  final manager = ModuleManager();

  // Core modules
  await manager.register(NotesModule());
  await manager.register(WeatherModule());
  await manager.register(UsersModule()); // Uses HttpClient from DioAdapter

  // Composite modules that may depend on others
  await manager.register(DashboardModule());

  // Shell module for navigation
  await manager.register(ShellModule());

  runApp(const AirNotesApp());
}
