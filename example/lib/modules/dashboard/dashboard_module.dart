import 'package:air_framework/air_framework.dart';

import 'ui/state/state.dart';
import 'ui/views/dashboard_page.dart';

/// Dashboard Module - Demonstrates cross-module state consumption.
///
/// Features showcased:
/// - Consuming state from other modules (Notes, Weather)
/// - Composite UI with widgets from multiple data sources
/// - Quick actions that interact with other modules
/// - EventBus subscription for reactive updates
///
/// This module has optional dependencies on Notes and Weather modules.
class DashboardModule extends AppModule {
  @override
  String get id => 'dashboard';

  @override
  String get name => 'Dashboard';

  @override
  String get version => '1.0.0';

  @override
  String get initialRoute => '/dashboard';

  @override
  List<String> get dependencies => ['notes', 'weather'];

  @override
  void onBind(AirDI di) {
    di.registerLazySingleton<DashboardState>(() => DashboardState());
  }

  @override
  Future<void> onInit(AirDI di) async {
    di.get<DashboardState>();
  }

  @override
  Future<void> onDispose(AirDI di) async {
    di.unregisterModule(id);
    super.onDispose(di);
  }

  @override
  List<AirRoute> get routes => [
        AirRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
      ];
}
