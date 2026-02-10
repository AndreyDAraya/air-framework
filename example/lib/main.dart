import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'modules/dashboard/dashboard_module.dart';
import 'modules/notes/notes_module.dart';
import 'modules/shell/shell_module.dart';
import 'modules/weather/weather_module.dart';

/// Entry point for AirNotes Pro - Air Framework Example App
///
/// This example demonstrates:
/// - Module registration and lifecycle (onBind/onInit)
/// - Dependency injection with AirDI
/// - Reactive state management with @GenerateState
/// - Cross-module communication via EventBus
/// - Routing with AirRouter
/// - DevTools integration
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Air State for reactive state management
  configureAirState();

  // Register all modules
  // Order matters: register dependencies before dependents
  final manager = ModuleManager();

  // Core modules
  await manager.register(NotesModule());
  await manager.register(WeatherModule());

  // Composite modules that may depend on others
  await manager.register(DashboardModule());

  // Shell module for navigation
  await manager.register(ShellModule());

  runApp(const AirNotesApp());
}
