import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_framework/framework/di/di.dart';

// Test classes
class TestService {
  final int id;
  TestService(this.id);
}

class TestFactory {
  final int id;
  TestFactory(this.id);
}

class AnotherService {
  final String name;
  AnotherService(this.name);
}

void main() {
  group('AirDI Lifecycle Tests', () {
    setUp(() {
      AirDI().clear();
    });

    test('Singleton: should return the same instance', () {
      final instance = TestService(1);
      AirDI().register<TestService>(instance);

      final retrieved1 = AirDI().get<TestService>();
      final retrieved2 = AirDI().get<TestService>();

      expect(retrieved1, equals(instance));
      expect(retrieved2, equals(instance));
      expect(retrieved1, same(retrieved2));
      debugPrint('✅ Singleton Test Passed: Instances are identical');
    });

    test(
      'LazySingleton: should create instance only when requested and reuse it',
      () {
        int creationCount = 0;

        AirDI().registerLazySingleton<TestService>(() {
          creationCount++;
          return TestService(creationCount);
        });

        // verification: not created yet
        expect(creationCount, 0);

        final instance1 = AirDI().get<TestService>();
        expect(creationCount, 1);
        expect(instance1.id, 1);

        final instance2 = AirDI().get<TestService>();
        expect(creationCount, 1); // Should not increase
        expect(instance2, same(instance1));

        debugPrint('✅ LazySingleton Test Passed: Created lazily and reused');
      },
    );

    test('Factory: should return a new instance every time', () {
      int creationCount = 0;

      AirDI().registerFactory<TestFactory>(() {
        creationCount++;
        return TestFactory(creationCount);
      });

      final instance1 = AirDI().get<TestFactory>();
      expect(creationCount, 1);
      expect(instance1.id, 1);

      final instance2 = AirDI().get<TestFactory>();
      expect(creationCount, 2);
      expect(instance2.id, 2);

      expect(instance1, isNot(same(instance2)));

      debugPrint('✅ Factory Test Passed: New instance created every time');
    });
  });

  group('AirDI Exception Tests', () {
    setUp(() {
      AirDI().clear();
    });

    test(
      'get: should throw DependencyNotFoundException for unregistered type',
      () {
        expect(
          () => AirDI().get<TestService>(),
          throwsA(isA<DependencyNotFoundException>()),
        );
      },
    );

    test('tryGet: should return null for unregistered type', () {
      final result = AirDI().tryGet<TestService>();
      expect(result, isNull);
    });

    test('register: should throw when overwriting without allowOverwrite', () {
      AirDI().register<TestService>(TestService(1));

      expect(
        () => AirDI().register<TestService>(TestService(2)),
        throwsA(isA<DependencyAlreadyRegisteredException>()),
      );
    });

    test('register: should succeed with allowOverwrite=true', () {
      AirDI().register<TestService>(TestService(1), moduleId: 'module1');
      AirDI().register<TestService>(
        TestService(2),
        moduleId: 'module2',
        allowOverwrite: true,
      );

      final retrieved = AirDI().get<TestService>();
      expect(retrieved.id, 2);
    });

    test('registerLazySingleton: should throw when overwriting', () {
      AirDI().registerLazySingleton<TestService>(() => TestService(1));

      expect(
        () => AirDI().registerLazySingleton<TestService>(() => TestService(2)),
        throwsA(isA<DependencyAlreadyRegisteredException>()),
      );
    });

    test('registerFactory: should throw when overwriting', () {
      AirDI().registerFactory<TestFactory>(() => TestFactory(1));

      expect(
        () => AirDI().registerFactory<TestFactory>(() => TestFactory(2)),
        throwsA(isA<DependencyAlreadyRegisteredException>()),
      );
    });
  });

  group('AirDI Module Ownership Tests', () {
    setUp(() {
      AirDI().clear();
    });

    test('isRegistered: should return correct status', () {
      expect(AirDI().isRegistered<TestService>(), isFalse);

      AirDI().register<TestService>(TestService(1));

      expect(AirDI().isRegistered<TestService>(), isTrue);
    });

    test(
      'getOwner: should return module ID that registered the dependency',
      () {
        AirDI().register<TestService>(TestService(1), moduleId: 'auth');

        expect(AirDI().getOwner<TestService>(), 'auth');
      },
    );

    test('getOwner: should return null when no moduleId was provided', () {
      AirDI().register<TestService>(TestService(1));

      expect(AirDI().getOwner<TestService>(), isNull);
    });

    test('unregister: should remove dependency', () {
      AirDI().register<TestService>(TestService(1));

      final result = AirDI().unregister<TestService>();

      expect(result, isTrue);
      expect(AirDI().isRegistered<TestService>(), isFalse);
    });

    test('unregister: should block unauthorized caller', () {
      AirDI().register<TestService>(TestService(1), moduleId: 'auth');

      final result = AirDI().unregister<TestService>(callerModuleId: 'other');

      expect(result, isFalse);
      expect(AirDI().isRegistered<TestService>(), isTrue);
    });

    test('unregister: should allow authorized caller', () {
      AirDI().register<TestService>(TestService(1), moduleId: 'auth');

      final result = AirDI().unregister<TestService>(callerModuleId: 'auth');

      expect(result, isTrue);
      expect(AirDI().isRegistered<TestService>(), isFalse);
    });

    test('unregisterModule: should remove all dependencies from module', () {
      AirDI().register<TestService>(TestService(1), moduleId: 'auth');
      AirDI().register<AnotherService>(
        AnotherService('test'),
        moduleId: 'auth',
      );
      AirDI().register<TestFactory>(TestFactory(1), moduleId: 'other');

      AirDI().unregisterModule('auth');

      expect(AirDI().isRegistered<TestService>(), isFalse);
      expect(AirDI().isRegistered<AnotherService>(), isFalse);
      expect(AirDI().isRegistered<TestFactory>(), isTrue);
    });
  });

  group('AirDI Debug Info Tests', () {
    setUp(() {
      AirDI().clear();
    });

    test('debugRegisteredTypes: should list all registered types', () {
      AirDI().register<TestService>(TestService(1));
      AirDI().register<AnotherService>(AnotherService('test'));

      final types = AirDI().debugRegisteredTypes;

      expect(types, contains('TestService'));
      expect(types, contains('AnotherService'));
    });

    test('debugRegistrationInfo: should include module IDs', () {
      AirDI().register<TestService>(TestService(1), moduleId: 'auth');
      AirDI().register<AnotherService>(AnotherService('test'));

      final info = AirDI().debugRegistrationInfo;

      expect(info['TestService'], 'auth');
      expect(info['AnotherService'], isNull);
    });
  });
}
