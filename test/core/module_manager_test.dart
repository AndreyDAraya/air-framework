import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_framework/core/app_module.dart';
import 'package:air_framework/core/module_manager.dart';
import 'package:air_framework/framework/di/di.dart';
import 'package:air_framework/framework/router/air_route.dart';

// Base test module
class BaseModule extends AppModule {
  @override
  String get id => 'base';

  @override
  String get name => 'Base Module';

  @override
  String get version => '1.0.0';

  @override
  String get initialRoute => '/base';

  @override
  List<AirRoute> get routes => [
    AirRoute(path: '/base', builder: (context, state) => const SizedBox()),
  ];
}

// Module that depends on base
class DependentModule extends AppModule {
  @override
  String get id => 'dependent';

  @override
  String get name => 'Dependent Module';

  @override
  String get version => '1.0.0';

  @override
  String get initialRoute => '/dependent';

  @override
  List<AirRoute> get routes => [
    AirRoute(path: '/dependent', builder: (context, state) => const SizedBox()),
  ];

  @override
  List<String> get dependencies => ['base'];
}

// Module with version requirement
class VersionedDependentModule extends AppModule {
  @override
  String get id => 'versioned_dependent';

  @override
  String get name => 'Versioned Dependent';

  @override
  String get version => '1.0.0';

  @override
  String get initialRoute => '/versioned';

  @override
  List<AirRoute> get routes => [];

  @override
  List<String> get dependencies => ['base:^1.0.0'];
}

// Module with same route for duplicate detection
class DuplicateRouteModule extends AppModule {
  @override
  String get id => 'duplicate';

  @override
  String get name => 'Duplicate Route Module';

  @override
  String get initialRoute => '/base'; // Same as BaseModule

  @override
  List<AirRoute> get routes => [
    AirRoute(path: '/base', builder: (context, state) => const SizedBox()),
  ];
}

void main() {
  group('ModuleManager Registration Tests', () {
    setUp(() async {
      await ModuleManager().reset();
      AirDI().clear();
    });

    test('Register single module', () async {
      final module = BaseModule();

      await ModuleManager().register(module);

      expect(ModuleManager().modules.length, 1);
      expect(ModuleManager().isRegistered('base'), isTrue);
    });

    test('Prevent duplicate registration', () async {
      final module1 = BaseModule();
      final module2 = BaseModule();

      await ModuleManager().register(module1);
      await ModuleManager().register(module2);

      expect(ModuleManager().modules.length, 1);
    });

    test('Get module by ID', () async {
      final module = BaseModule();
      await ModuleManager().register(module);

      final retrieved = ModuleManager().getModule('base');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'base');
    });

    test('Get module returns null for unregistered', () {
      final retrieved = ModuleManager().getModule('nonexistent');

      expect(retrieved, isNull);
    });

    test('isInitialized returns correct status', () async {
      final module = BaseModule();
      await ModuleManager().register(module);

      expect(ModuleManager().isInitialized('base'), isTrue);
    });
  });

  group('ModuleManager Dependency Tests', () {
    setUp(() async {
      await ModuleManager().reset();
      AirDI().clear();
    });

    test('Register with satisfied dependency', () async {
      await ModuleManager().register(BaseModule());
      await ModuleManager().register(DependentModule());

      expect(ModuleManager().isRegistered('dependent'), isTrue);
    });

    test('Throw when dependency is missing', () async {
      expect(
        () => ModuleManager().register(DependentModule()),
        throwsA(isA<StateError>()),
      );
    });

    test('Register with versioned dependency', () async {
      await ModuleManager().register(BaseModule());
      await ModuleManager().register(VersionedDependentModule());

      expect(ModuleManager().isRegistered('versioned_dependent'), isTrue);
    });
  });

  group('ModuleManager Unregister Tests', () {
    setUp(() async {
      await ModuleManager().reset();
      AirDI().clear();
    });

    test('Unregister module', () async {
      await ModuleManager().register(BaseModule());

      await ModuleManager().unregister('base');

      expect(ModuleManager().isRegistered('base'), isFalse);
    });

    test('Unregister nonexistent module does nothing', () async {
      await ModuleManager().unregister('nonexistent');

      expect(ModuleManager().modules, isEmpty);
    });

    test('Cannot unregister module with dependents', () async {
      await ModuleManager().register(BaseModule());
      await ModuleManager().register(DependentModule());

      expect(
        () => ModuleManager().unregister('base'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ModuleManager Route Tests', () {
    setUp(() async {
      await ModuleManager().reset();
      AirDI().clear();
    });

    test('Get all routes from modules', () async {
      await ModuleManager().register(BaseModule());

      final routes = ModuleManager().getAirRoutes();

      expect(routes.length, 1);
      expect(routes.first.path, '/base');
    });

    test('Empty routes when no modules', () {
      final routes = ModuleManager().getAirRoutes();

      expect(routes, isEmpty);
    });
  });

  group('ModuleManager Context Tests', () {
    setUp(() async {
      await ModuleManager().reset();
      AirDI().clear();
    });

    test('Get module context after registration', () async {
      await ModuleManager().register(BaseModule());

      final context = ModuleManager().getContext('base');

      expect(context, isNotNull);
      expect(context!.moduleId, 'base');
    });

    test('Context is null for unregistered module', () {
      final context = ModuleManager().getContext('nonexistent');

      expect(context, isNull);
    });
  });
}
