import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_framework/core/app_module.dart';
import 'package:air_framework/framework/di/di.dart';
import 'package:air_framework/framework/router/air_route.dart';

// Test module implementation
class TestModule extends AppModule {
  final List<String> callOrder = [];
  bool shouldThrowOnInit = false;
  bool shouldThrowOnDispose = false;

  @override
  String get id => 'test_module';

  @override
  String get name => 'Test Module';

  @override
  String get version => '1.0.0';

  @override
  String get initialRoute => '/test';

  @override
  List<AirRoute> get routes => [
    AirRoute(path: '/test', builder: (context, state) => const SizedBox()),
  ];

  @override
  List<String> get dependencies => [];

  @override
  void onBind(AirDI di) {
    callOrder.add('onBind');
    super.onBind(di);
  }

  @override
  Future<void> onInit(AirDI di) async {
    callOrder.add('onInit');
    if (shouldThrowOnInit) {
      throw Exception('Init failed');
    }
    await super.onInit(di);
  }

  @override
  Future<void> onDispose(AirDI di) async {
    callOrder.add('onDispose');
    if (shouldThrowOnDispose) {
      throw Exception('Dispose failed');
    }
    await super.onDispose(di);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    callOrder.add('onError');
    super.onError(error, stackTrace);
  }
}

// Module with dependencies
class DependentModule extends AppModule {
  @override
  String get id => 'dependent_module';

  @override
  String get name => 'Dependent Module';

  @override
  String get initialRoute => '/dependent';

  @override
  List<AirRoute> get routes => [];

  @override
  List<String> get dependencies => ['base_module'];

  @override
  List<String> get optionalDependencies => ['optional_module'];
}

void main() {
  group('AppModule Lifecycle State Tests', () {
    test('Initial state is unloaded', () {
      final module = TestModule();

      expect(module.state, ModuleLifecycleState.unloaded);
    });

    test('State transitions through binding', () {
      final module = TestModule();
      final di = AirDI();

      module.onBind(di);

      expect(module.state, ModuleLifecycleState.bound);
    });

    test('State transitions through initialization', () async {
      final module = TestModule();
      final di = AirDI();

      module.onBind(di);
      await module.onInit(di);

      expect(module.state, ModuleLifecycleState.initialized);
    });

    test('State transitions through disposal', () async {
      final module = TestModule();
      final di = AirDI();

      module.onBind(di);
      await module.onInit(di);
      await module.onDispose(di);

      expect(module.state, ModuleLifecycleState.disposed);
    });
  });

  group('AppModule Callback Order Tests', () {
    test('Lifecycle methods are called in correct order', () async {
      final module = TestModule();
      final di = AirDI();

      module.onBind(di);
      await module.onInit(di);
      await module.onDispose(di);

      expect(module.callOrder, ['onBind', 'onInit', 'onDispose']);
    });
  });

  group('AppModule Property Tests', () {
    test('Default version is 1.0.0', () {
      final module = TestModule();

      expect(module.version, '1.0.0');
    });

    test('Default icon is Icons.widgets', () {
      final module = TestModule();

      expect(module.icon, Icons.widgets);
    });

    test('Default color is Colors.teal', () {
      final module = TestModule();

      expect(module.color, Colors.teal);
    });

    test('Default dependencies list is empty', () {
      final module = TestModule();

      expect(module.dependencies, isEmpty);
    });

    test('Default optionalDependencies list is empty', () {
      final module = TestModule();

      expect(module.optionalDependencies, isEmpty);
    });
  });

  group('AppModule Dependencies Tests', () {
    test('Module can declare dependencies', () {
      final module = DependentModule();

      expect(module.dependencies, contains('base_module'));
    });

    test('Module can declare optional dependencies', () {
      final module = DependentModule();

      expect(module.optionalDependencies, contains('optional_module'));
    });
  });

  group('AppModule Error Handling Tests', () {
    test('onError is accessible for error handling', () {
      final module = TestModule();

      expect(
        () => module.onError(Exception('test'), StackTrace.current),
        returnsNormally,
      );
      expect(module.callOrder, contains('onError'));
    });
  });
}
