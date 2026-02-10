import 'package:air_framework/air_framework.dart';

import 'services/weather_service.dart';
import 'ui/state/state.dart';
import 'ui/views/weather_page.dart';

/// Weather Module - Demonstrates async data fetching and cross-module communication.
///
/// Features showcased:
/// - Mock API service with simulated network delays
/// - Loading and error state handling
/// - EventBus events for cross-module data sharing
/// - City selection with state persistence
class WeatherModule extends AppModule {
  @override
  String get id => 'weather';

  @override
  String get name => 'Weather';

  @override
  String get version => '1.0.0';

  @override
  String get initialRoute => '/weather';

  @override
  void onBind(AirDI di) {
    // Register weather service
    di.registerLazySingleton<WeatherService>(() => WeatherService());
    // Register weather state
    di.registerLazySingleton<WeatherState>(() => WeatherState());
  }

  @override
  Future<void> onInit(AirDI di) async {
    // Initialize state (triggers onInit which fetches initial weather)
    di.get<WeatherState>();
  }

  @override
  Future<void> onDispose(AirDI di) async {
    di.unregisterModule(id);
    super.onDispose(di);
  }

  @override
  List<AirRoute> get routes => [
        AirRoute(
          path: '/weather',
          builder: (context, state) => const WeatherPage(),
        ),
      ];
}
