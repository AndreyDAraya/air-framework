import 'package:flutter_test/flutter_test.dart';
import 'package:air_framework/framework/security/secure_service_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureServiceRegistry Service Tests', () {
    setUp(() {
      SecureServiceRegistry().clearAll();
    });

    test('Register public service', () {
      SecureServiceRegistry().registerService(
        name: 'test.service',
        ownerModuleId: 'test_module',
        service: () => 'service_result',
      );

      expect(SecureServiceRegistry().hasService('test.service'), isTrue);
    });

    test('Get public service by any caller', () {
      SecureServiceRegistry().registerService(
        name: 'test.service',
        ownerModuleId: 'owner_module',
        service: () => 'result',
      );

      final service = SecureServiceRegistry().getService<Function>(
        'test.service',
        callerModuleId: 'any_module',
      );

      expect(service, isNotNull);
      expect(service!(), 'result');
    });

    test('Register restricted service', () {
      SecureServiceRegistry().registerService(
        name: 'restricted.service',
        ownerModuleId: 'owner_module',
        service: () => 'secret',
        allowedCallers: ['trusted_module'],
      );

      final descriptor = SecureServiceRegistry().getDescriptor(
        'restricted.service',
      );

      expect(descriptor, isNotNull);
      expect(descriptor!.isPublic, isFalse);
    });

    test('Allowed caller can access restricted service', () {
      SecureServiceRegistry().registerService(
        name: 'restricted.service',
        ownerModuleId: 'owner_module',
        service: () => 'secret',
        allowedCallers: ['trusted_module'],
      );

      final service = SecureServiceRegistry().getService<Function>(
        'restricted.service',
        callerModuleId: 'trusted_module',
      );

      expect(service, isNotNull);
    });

    test('Unauthorized caller cannot access restricted service', () {
      SecureServiceRegistry().registerService(
        name: 'restricted.service',
        ownerModuleId: 'owner_module',
        service: () => 'secret',
        allowedCallers: ['trusted_module'],
      );

      final service = SecureServiceRegistry().getService<Function>(
        'restricted.service',
        callerModuleId: 'untrusted_module',
      );

      expect(service, isNull);
    });

    test('Get non-existent service returns null', () {
      final service = SecureServiceRegistry().getService<Function>(
        'nonexistent',
        callerModuleId: 'any',
      );

      expect(service, isNull);
    });

    test('Unregister service by owner', () {
      SecureServiceRegistry().registerService(
        name: 'test.service',
        ownerModuleId: 'owner_module',
        service: () => 'result',
      );

      SecureServiceRegistry().unregisterService(
        'test.service',
        callerModuleId: 'owner_module',
      );

      expect(SecureServiceRegistry().hasService('test.service'), isFalse);
    });

    test('Non-owner cannot unregister service', () {
      SecureServiceRegistry().registerService(
        name: 'test.service',
        ownerModuleId: 'owner_module',
        service: () => 'result',
      );

      SecureServiceRegistry().unregisterService(
        'test.service',
        callerModuleId: 'other_module',
      );

      expect(SecureServiceRegistry().hasService('test.service'), isTrue);
    });

    test('Unregister all services from module', () {
      SecureServiceRegistry().registerService(
        name: 'service1',
        ownerModuleId: 'module1',
        service: () => 'a',
      );
      SecureServiceRegistry().registerService(
        name: 'service2',
        ownerModuleId: 'module1',
        service: () => 'b',
      );
      SecureServiceRegistry().registerService(
        name: 'service3',
        ownerModuleId: 'module2',
        service: () => 'c',
      );

      SecureServiceRegistry().unregisterModuleServices('module1');

      expect(SecureServiceRegistry().hasService('service1'), isFalse);
      expect(SecureServiceRegistry().hasService('service2'), isFalse);
      expect(SecureServiceRegistry().hasService('service3'), isTrue);
    });

    test('Get module services', () {
      SecureServiceRegistry().registerService(
        name: 'service1',
        ownerModuleId: 'module1',
        service: () => 'a',
      );
      SecureServiceRegistry().registerService(
        name: 'service2',
        ownerModuleId: 'module1',
        service: () => 'b',
      );

      final services = SecureServiceRegistry().getModuleServices('module1');

      expect(services.length, 2);
    });

    test('Get available services for caller', () {
      SecureServiceRegistry().registerService(
        name: 'public',
        ownerModuleId: 'owner',
        service: () => 'a',
      );
      SecureServiceRegistry().registerService(
        name: 'restricted',
        ownerModuleId: 'owner',
        service: () => 'b',
        allowedCallers: ['trusted'],
      );

      final availableForTrusted = SecureServiceRegistry().getAvailableServices(
        'trusted',
      );
      final availableForOther = SecureServiceRegistry().getAvailableServices(
        'other',
      );

      expect(availableForTrusted.length, 2);
      expect(availableForOther.length, 1);
    });
  });

  group('SecureServiceRegistry Data Tests', () {
    setUp(() {
      SecureServiceRegistry().clearAll();
    });

    test('Set and get data', () {
      SecureServiceRegistry().setData(
        'user.name',
        'John',
        callerModuleId: 'module1',
      );

      final value = SecureServiceRegistry().getData<String>(
        'user.name',
        callerModuleId: 'module1',
      );

      expect(value, 'John');
    });

    test('Set secure data with TTL', () {
      SecureServiceRegistry().setSecureData<String>(
        'token',
        'secret123',
        callerModuleId: 'auth',
        ttl: const Duration(hours: 1),
      );

      final value = SecureServiceRegistry().getSecureData<String>(
        'token',
        callerModuleId: 'auth',
      );

      expect(value, 'secret123');
    });

    test('Secure data expires after TTL', () async {
      SecureServiceRegistry().setSecureData<String>(
        'token',
        'secret123',
        callerModuleId: 'auth',
        ttl: const Duration(milliseconds: 50),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final value = SecureServiceRegistry().getSecureData<String>(
        'token',
        callerModuleId: 'auth',
      );

      expect(value, isNull);
    });
  });

  group('SecureServiceRegistry Interaction Tests', () {
    setUp(() {
      SecureServiceRegistry().clearAll();
    });

    test('Record module interaction', () {
      SecureServiceRegistry().recordInteraction(
        ModuleInteraction(
          sourceId: 'module1',
          targetId: 'module2',
          type: InteractionType.service,
          detail: 'test.service',
        ),
      );

      expect(SecureServiceRegistry().interactions.length, 1);
    });

    test('Interaction contains correct data', () {
      SecureServiceRegistry().recordInteraction(
        ModuleInteraction(
          sourceId: 'auth',
          targetId: 'user',
          type: InteractionType.event,
          detail: 'login',
        ),
      );

      final interaction = SecureServiceRegistry().interactions.first;

      expect(interaction.sourceId, 'auth');
      expect(interaction.targetId, 'user');
      expect(interaction.type, InteractionType.event);
      expect(interaction.detail, 'login');
    });

    test('Relationships are tracked', () {
      SecureServiceRegistry().recordInteraction(
        ModuleInteraction(
          sourceId: 'a',
          targetId: 'b',
          type: InteractionType.service,
          detail: 'test',
        ),
      );

      expect(SecureServiceRegistry().relationships, contains('a->b'));
    });
  });

  group('SecureData Tests', () {
    test('SecureData stores value', () {
      final data = SecureData<String>('secret', ownerModuleId: 'auth');

      expect(data.value, 'secret');
      expect(data.ownerModuleId, 'auth');
    });

    test('SecureData isExpired with no expiration', () {
      final data = SecureData<String>('secret', ownerModuleId: 'auth');

      expect(data.isExpired, isFalse);
    });

    test('SecureData isExpired with future expiration', () {
      final data = SecureData<String>(
        'secret',
        ownerModuleId: 'auth',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(data.isExpired, isFalse);
    });

    test('SecureData isExpired with past expiration', () {
      final data = SecureData<String>(
        'secret',
        ownerModuleId: 'auth',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(data.isExpired, isTrue);
    });
  });

  group('ModuleInteraction Tests', () {
    test('Interaction has timestamp', () {
      final interaction = ModuleInteraction(
        sourceId: 'a',
        targetId: 'b',
        type: InteractionType.service,
        detail: 'test',
      );

      expect(interaction.timestamp, isNotNull);
    });

    test('InteractionType enum values', () {
      expect(InteractionType.values, contains(InteractionType.service));
      expect(InteractionType.values, contains(InteractionType.event));
      expect(InteractionType.values, contains(InteractionType.data));
    });
  });
}
