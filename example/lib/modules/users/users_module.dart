import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import 'services/user_service.dart';
import 'ui/users_page.dart';

/// Users Module - Demonstrates the Adapter pattern with real HTTP calls.
///
/// This module uses [UserService] which depends on the abstract [HttpClient]
/// contract provided by the DioAdapter. It fetches real data from the
/// JSONPlaceholder API (https://jsonplaceholder.typicode.com).
///
/// **Key point:** This module has ZERO knowledge of Dio. It only knows
/// about [HttpClient], which is registered by the adapter layer.
class UsersModule extends AppModule {
  @override
  String get id => 'users';

  @override
  String get name => 'Users';

  @override
  String get version => '1.0.0';

  @override
  IconData get icon => Icons.people;

  @override
  Color get color => Colors.indigo;

  @override
  String get initialRoute => '/users';

  @override
  void onBind(AirDI di) {
    // UserService depends on HttpClient (provided by DioAdapter)
    di.registerLazySingleton<UserService>(
      () => UserService(di.get()),
    );
    super.onBind(di);
  }

  @override
  List<AirRoute> get routes => [
        AirRoute(
          path: '/users',
          builder: (context, state) => const UsersPage(),
        ),
      ];
}
