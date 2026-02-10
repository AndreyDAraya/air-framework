import 'package:air_framework/framework/di/di.dart';
import 'package:air_framework/framework/state/air.dart';

extension AirDIControllerExtension on AirState {
  /// Inject a dependency from the DI container
  T inject<T>() => AirDI().get<T>();
}
