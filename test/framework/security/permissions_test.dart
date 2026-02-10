import 'package:flutter_test/flutter_test.dart';
import 'package:air_framework/framework/security/permissions.dart';

void main() {
  group('Permission Enum Tests', () {
    test('All permission types exist', () {
      expect(Permission.values, contains(Permission.dataRead));
      expect(Permission.values, contains(Permission.dataWrite));
      expect(Permission.values, contains(Permission.serviceCall));
      expect(Permission.values, contains(Permission.eventEmit));
      expect(Permission.values, contains(Permission.eventListen));
      expect(Permission.values, contains(Permission.routeAccess));
      expect(Permission.values, contains(Permission.fullAccess));
    });
  });

  group('ScopedPermission Tests', () {
    test('Match any resource when pattern is null', () {
      const permission = ScopedPermission(Permission.dataRead);

      expect(permission.matches(Permission.dataRead, 'any.resource'), isTrue);
      expect(permission.matches(Permission.dataRead, null), isTrue);
    });

    test('Match exact pattern', () {
      const permission = ScopedPermission(Permission.serviceCall, 'auth.login');

      expect(permission.matches(Permission.serviceCall, 'auth.login'), isTrue);
      expect(
        permission.matches(Permission.serviceCall, 'auth.logout'),
        isFalse,
      );
    });

    test('Match wildcard pattern', () {
      const permission = ScopedPermission(Permission.serviceCall, 'auth.*');

      expect(permission.matches(Permission.serviceCall, 'auth.login'), isTrue);
      expect(permission.matches(Permission.serviceCall, 'auth.logout'), isTrue);
      expect(
        permission.matches(Permission.serviceCall, 'user.profile'),
        isFalse,
      );
    });

    test('fullAccess matches any permission type', () {
      const permission = ScopedPermission(Permission.fullAccess);

      expect(permission.matches(Permission.dataRead, 'any'), isTrue);
      expect(permission.matches(Permission.serviceCall, 'any'), isTrue);
      expect(permission.matches(Permission.eventEmit, 'any'), isTrue);
    });

    test('Does not match different permission type', () {
      const permission = ScopedPermission(Permission.dataRead);

      expect(permission.matches(Permission.dataWrite, 'any'), isFalse);
    });

    test('toString representation', () {
      const permission = ScopedPermission(Permission.dataRead, 'user.*');

      expect(permission.toString(), contains('dataRead'));
      expect(permission.toString(), contains('user.*'));
    });
  });

  group('ModulePermissions Tests', () {
    test('Allows granted permission', () {
      const permissions = ModulePermissions([
        ScopedPermission(Permission.dataRead),
        ScopedPermission(Permission.serviceCall, 'auth.*'),
      ]);

      expect(permissions.allows(Permission.dataRead), isTrue);
      expect(permissions.allows(Permission.serviceCall, 'auth.login'), isTrue);
    });

    test('Denies non-granted permission', () {
      const permissions = ModulePermissions([
        ScopedPermission(Permission.dataRead),
      ]);

      expect(permissions.allows(Permission.dataWrite), isFalse);
      expect(permissions.allows(Permission.serviceCall), isFalse);
    });

    test('Denies out-of-scope resource', () {
      const permissions = ModulePermissions([
        ScopedPermission(Permission.serviceCall, 'auth.*'),
      ]);

      expect(
        permissions.allows(Permission.serviceCall, 'user.profile'),
        isFalse,
      );
    });
  });

  group('PermissionChecker Tests', () {
    setUp(() {
      PermissionChecker().clear();
      PermissionChecker().enable();
    });

    test('Register module permissions', () {
      PermissionChecker().registerModule(
        'test_module',
        const ModulePermissions([ScopedPermission(Permission.dataRead)]),
      );

      expect(PermissionChecker().registeredModules, contains('test_module'));
    });

    test('Get module permissions', () {
      const permissions = ModulePermissions([
        ScopedPermission(Permission.dataRead),
      ]);

      PermissionChecker().registerModule('test_module', permissions);

      final retrieved = PermissionChecker().getModulePermissions('test_module');

      expect(retrieved, isNotNull);
    });

    test('Check permission granted', () {
      PermissionChecker().registerModule(
        'test_module',
        const ModulePermissions([ScopedPermission(Permission.dataRead)]),
      );

      final result = PermissionChecker().checkPermission(
        'test_module',
        Permission.dataRead,
        logViolation: false,
      );

      expect(result, isTrue);
    });

    test('Check permission denied', () {
      PermissionChecker().registerModule(
        'test_module',
        const ModulePermissions([ScopedPermission(Permission.dataRead)]),
      );

      final result = PermissionChecker().checkPermission(
        'test_module',
        Permission.dataWrite,
        logViolation: false,
      );

      expect(result, isFalse);
    });

    test('Check permission denied for unregistered module', () {
      final result = PermissionChecker().checkPermission(
        'unregistered_module',
        Permission.dataRead,
        logViolation: false,
      );

      expect(result, isFalse);
    });

    test('Disabled checker allows everything', () {
      PermissionChecker().disable();

      final result = PermissionChecker().checkPermission(
        'any_module',
        Permission.fullAccess,
      );

      expect(result, isTrue);
    });

    test('Enable and disable checker', () {
      PermissionChecker().disable();
      expect(PermissionChecker().isEnabled, isFalse);

      PermissionChecker().enable();
      expect(PermissionChecker().isEnabled, isTrue);
    });

    test('Unregister module', () {
      PermissionChecker().registerModule(
        'test_module',
        const ModulePermissions([]),
      );

      PermissionChecker().unregisterModule('test_module');

      expect(
        PermissionChecker().registeredModules,
        isNot(contains('test_module')),
      );
    });

    test('requirePermission throws on denied', () {
      PermissionChecker().registerModule(
        'test_module',
        const ModulePermissions([]),
      );

      expect(
        () => PermissionChecker().requirePermission(
          'test_module',
          Permission.dataRead,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('requirePermission succeeds on granted', () {
      PermissionChecker().registerModule(
        'test_module',
        const ModulePermissions([ScopedPermission(Permission.dataRead)]),
      );

      expect(
        () => PermissionChecker().requirePermission(
          'test_module',
          Permission.dataRead,
        ),
        returnsNormally,
      );
    });
  });

  group('PermissionDeniedException Tests', () {
    test('Exception message format', () {
      final exception = PermissionDeniedException(
        moduleId: 'test_module',
        permission: Permission.dataRead,
      );

      final message = exception.toString();

      expect(message, contains('test_module'));
      expect(message, contains('dataRead'));
    });

    test('Exception with resource', () {
      final exception = PermissionDeniedException(
        moduleId: 'test_module',
        permission: Permission.serviceCall,
        resource: 'auth.login',
      );

      final message = exception.toString();

      expect(message, contains('auth.login'));
    });
  });
}
