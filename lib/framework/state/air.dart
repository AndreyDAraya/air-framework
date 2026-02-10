import 'package:air_state/air_state.dart';
import '../bridge/secure_air_delegate.dart';

export 'package:air_state/air_state.dart';

/// Configure the Air State framework with the default secure delegate.
/// This should be called at the start of the application.
void configureAirState() {
  Air.configure(delegate: SecureAirDelegate());
}
