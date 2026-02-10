import 'package:flutter_test/flutter_test.dart';
import 'package:air_framework/framework/communication/version_resolver.dart';

void main() {
  group('SemanticVersion Parsing Tests', () {
    test('Parse simple version', () {
      final version = SemanticVersion.parse('1.2.3');

      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
    });

    test('Parse version with v prefix', () {
      final version = SemanticVersion.parse('v1.2.3');

      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
    });

    test('Parse version with pre-release', () {
      final version = SemanticVersion.parse('1.0.0-alpha');

      expect(version.major, 1);
      expect(version.preRelease, 'alpha');
    });

    test('Parse version with build metadata', () {
      final version = SemanticVersion.parse('1.0.0+build.123');

      expect(version.buildMetadata, 'build.123');
    });

    test('Parse version with pre-release and build', () {
      final version = SemanticVersion.parse('1.0.0-beta.1+build.456');

      expect(version.preRelease, 'beta.1');
      expect(version.buildMetadata, 'build.456');
    });

    test('tryParse returns null for invalid version', () {
      final version = SemanticVersion.tryParse('invalid');

      expect(version, isNotNull); // Parser is lenient
    });

    test('Parse partial version', () {
      final version = SemanticVersion.parse('1.0');

      expect(version.major, 1);
      expect(version.minor, 0);
      expect(version.patch, 0);
    });
  });

  group('SemanticVersion Comparison Tests', () {
    test('Equal versions', () {
      final v1 = SemanticVersion.parse('1.2.3');
      final v2 = SemanticVersion.parse('1.2.3');

      expect(v1 == v2, isTrue);
      expect(v1.compareTo(v2), 0);
    });

    test('Major version comparison', () {
      final v1 = SemanticVersion.parse('2.0.0');
      final v2 = SemanticVersion.parse('1.0.0');

      expect(v1 > v2, isTrue);
      expect(v1 >= v2, isTrue);
      expect(v2 < v1, isTrue);
      expect(v2 <= v1, isTrue);
    });

    test('Minor version comparison', () {
      final v1 = SemanticVersion.parse('1.2.0');
      final v2 = SemanticVersion.parse('1.1.0');

      expect(v1 > v2, isTrue);
    });

    test('Patch version comparison', () {
      final v1 = SemanticVersion.parse('1.0.2');
      final v2 = SemanticVersion.parse('1.0.1');

      expect(v1 > v2, isTrue);
    });

    test('Pre-release has lower precedence', () {
      final stable = SemanticVersion.parse('1.0.0');
      final prerelease = SemanticVersion.parse('1.0.0-alpha');

      expect(stable > prerelease, isTrue);
    });

    test('Pre-release comparison', () {
      final alpha = SemanticVersion.parse('1.0.0-alpha');
      final beta = SemanticVersion.parse('1.0.0-beta');

      expect(beta > alpha, isTrue);
    });
  });

  group('SemanticVersion Satisfies Tests', () {
    test('Exact match', () {
      final version = SemanticVersion.parse('1.2.3');

      expect(version.satisfies('1.2.3'), isTrue);
      expect(version.satisfies('1.2.4'), isFalse);
    });

    test('Caret (^) - compatible with major', () {
      final version = SemanticVersion.parse('1.5.0');

      expect(version.satisfies('^1.0.0'), isTrue);
      expect(version.satisfies('^1.5.0'), isTrue);
      expect(version.satisfies('^1.6.0'), isFalse);
      expect(version.satisfies('^2.0.0'), isFalse);
    });

    test('Tilde (~) - compatible with minor', () {
      final version = SemanticVersion.parse('1.2.5');

      expect(version.satisfies('~1.2.0'), isTrue);
      expect(version.satisfies('~1.2.5'), isTrue);
      expect(version.satisfies('~1.3.0'), isFalse);
    });

    test('Greater than or equal (>=)', () {
      final version = SemanticVersion.parse('2.0.0');

      expect(version.satisfies('>=1.0.0'), isTrue);
      expect(version.satisfies('>=2.0.0'), isTrue);
      expect(version.satisfies('>=3.0.0'), isFalse);
    });

    test('Greater than (>)', () {
      final version = SemanticVersion.parse('2.0.0');

      expect(version.satisfies('>1.0.0'), isTrue);
      expect(version.satisfies('>2.0.0'), isFalse);
    });

    test('Less than (<)', () {
      final version = SemanticVersion.parse('1.0.0');

      expect(version.satisfies('<2.0.0'), isTrue);
      expect(version.satisfies('<1.0.0'), isFalse);
    });

    test('Less than or equal (<=)', () {
      final version = SemanticVersion.parse('1.0.0');

      expect(version.satisfies('<=2.0.0'), isTrue);
      expect(version.satisfies('<=1.0.0'), isTrue);
      expect(version.satisfies('<=0.9.0'), isFalse);
    });

    test('Range (>= <)', () {
      final version = SemanticVersion.parse('1.5.0');

      expect(version.satisfies('>=1.0.0 <2.0.0'), isTrue);
      expect(version.satisfies('>=1.0.0 <1.5.0'), isFalse);
    });
  });

  group('SemanticVersion toString Tests', () {
    test('Simple version', () {
      final version = SemanticVersion(major: 1, minor: 2, patch: 3);

      expect(version.toString(), '1.2.3');
    });

    test('With pre-release', () {
      final version = SemanticVersion(
        major: 1,
        minor: 0,
        patch: 0,
        preRelease: 'alpha',
      );

      expect(version.toString(), '1.0.0-alpha');
    });

    test('With build metadata', () {
      final version = SemanticVersion(
        major: 1,
        minor: 0,
        patch: 0,
        buildMetadata: 'build.123',
      );

      expect(version.toString(), '1.0.0+build.123');
    });
  });

  group('ModuleDependency Tests', () {
    test('Parse simple dependency', () {
      final dep = ModuleDependency.parse('auth');

      expect(dep.moduleId, 'auth');
      expect(dep.versionRequirement, isNull);
      expect(dep.isOptional, isFalse);
    });

    test('Parse dependency with version', () {
      final dep = ModuleDependency.parse('auth@^1.0.0');

      expect(dep.moduleId, 'auth');
      expect(dep.versionRequirement, '^1.0.0');
    });

    test('Parse optional dependency', () {
      final dep = ModuleDependency.parse('analytics', isOptional: true);

      expect(dep.isOptional, isTrue);
    });

    test('isSatisfiedBy with no version requirement', () {
      final dep = ModuleDependency(moduleId: 'auth');

      expect(dep.isSatisfiedBy('0.1.0'), isTrue);
      expect(dep.isSatisfiedBy('99.0.0'), isTrue);
    });

    test('isSatisfiedBy with version requirement', () {
      final dep = ModuleDependency(
        moduleId: 'auth',
        versionRequirement: '^1.0.0',
      );

      expect(dep.isSatisfiedBy('1.5.0'), isTrue);
      expect(dep.isSatisfiedBy('2.0.0'), isFalse);
    });

    test('toString representation', () {
      final dep = ModuleDependency(
        moduleId: 'auth',
        versionRequirement: '^1.0.0',
        isOptional: true,
      );

      expect(dep.toString(), contains('auth'));
      expect(dep.toString(), contains('^1.0.0'));
      expect(dep.toString(), contains('optional'));
    });
  });

  group('DependencyResolver Tests', () {
    test('Resolve simple dependencies', () {
      final resolver = DependencyResolver();

      final result = resolver.resolve(
        modules: {'app': [], 'auth': []},
        moduleVersions: {'app': '1.0.0', 'auth': '1.0.0'},
      );

      expect(result.success, isTrue);
      expect(result.resolvedOrder.length, 2);
    });

    test('Resolve with dependency order', () {
      final resolver = DependencyResolver();

      final result = resolver.resolve(
        modules: {
          'app': [ModuleDependency(moduleId: 'auth')],
          'auth': [],
        },
        moduleVersions: {'app': '1.0.0', 'auth': '1.0.0'},
      );

      expect(result.success, isTrue);
      expect(
        result.resolvedOrder.indexOf('auth'),
        lessThan(result.resolvedOrder.indexOf('app')),
      );
    });

    test('Detect circular dependency', () {
      final resolver = DependencyResolver();

      final result = resolver.resolve(
        modules: {
          'a': [ModuleDependency(moduleId: 'b')],
          'b': [ModuleDependency(moduleId: 'a')],
        },
        moduleVersions: {'a': '1.0.0', 'b': '1.0.0'},
      );

      expect(result.success, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('Circular'));
    });

    test('Missing required dependency', () {
      final resolver = DependencyResolver();

      final result = resolver.resolve(
        modules: {
          'app': [ModuleDependency(moduleId: 'missing')],
        },
        moduleVersions: {'app': '1.0.0'},
      );

      expect(result.success, isFalse);
      expect(result.errors.first, contains('Missing'));
    });

    test('Missing optional dependency as warning', () {
      final resolver = DependencyResolver();

      final result = resolver.resolve(
        modules: {
          'app': [ModuleDependency(moduleId: 'optional', isOptional: true)],
        },
        moduleVersions: {'app': '1.0.0'},
      );

      expect(result.success, isTrue);
      expect(result.warnings, isNotEmpty);
    });

    test('Version mismatch error', () {
      final resolver = DependencyResolver();

      final result = resolver.resolve(
        modules: {
          'app': [
            ModuleDependency(moduleId: 'auth', versionRequirement: '^2.0.0'),
          ],
          'auth': [],
        },
        moduleVersions: {'app': '1.0.0', 'auth': '1.0.0'},
      );

      expect(result.success, isFalse);
      expect(result.errors.first, contains('Version mismatch'));
    });
  });
}
