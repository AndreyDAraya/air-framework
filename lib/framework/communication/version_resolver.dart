/// Semantic version representation and comparison
class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;
  final String? buildMetadata;

  SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
    this.buildMetadata,
  });

  /// Parse a version string (e.g., "1.2.3", "1.2.3-alpha", "1.2.3+build.1")
  factory SemanticVersion.parse(String version) {
    // Remove leading 'v' if present
    String v = version.startsWith('v') ? version.substring(1) : version;

    // Split by + to separate build metadata
    String? buildMetadata;
    if (v.contains('+')) {
      final parts = v.split('+');
      v = parts[0];
      buildMetadata = parts.length > 1 ? parts[1] : null;
    }

    // Split by - to separate pre-release
    String? preRelease;
    if (v.contains('-')) {
      final parts = v.split('-');
      v = parts[0];
      preRelease = parts.length > 1 ? parts.sublist(1).join('-') : null;
    }

    // Parse major.minor.patch
    final parts = v.split('.');
    if (parts.isEmpty) {
      throw FormatException('Invalid version format: $version');
    }

    int major = int.tryParse(parts[0]) ?? 0;
    int minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    int patch = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      preRelease: preRelease,
      buildMetadata: buildMetadata,
    );
  }

  /// Try to parse, returns null on failure
  static SemanticVersion? tryParse(String version) {
    try {
      return SemanticVersion.parse(version);
    } catch (_) {
      return null;
    }
  }

  @override
  int compareTo(SemanticVersion other) {
    // Compare major
    if (major != other.major) return major.compareTo(other.major);

    // Compare minor
    if (minor != other.minor) return minor.compareTo(other.minor);

    // Compare patch
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Pre-release versions have lower precedence
    if (preRelease != null && other.preRelease == null) return -1;
    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease != null) {
      return preRelease!.compareTo(other.preRelease!);
    }

    return 0;
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) {
    if (other is! SemanticVersion) return false;
    return major == other.major &&
        minor == other.minor &&
        patch == other.patch &&
        preRelease == other.preRelease;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);

  @override
  String toString() {
    String result = '$major.$minor.$patch';
    if (preRelease != null) result += '-$preRelease';
    if (buildMetadata != null) result += '+$buildMetadata';
    return result;
  }

  /// Check if this version is compatible with a version requirement
  /// Examples:
  /// - "1.0.0" (exact)
  /// - "^1.0.0" (compatible with 1.x.x)
  /// - "~1.0.0" (compatible with 1.0.x)
  /// - ">=1.0.0" (greater than or equal)
  /// - ">=1.0.0 <2.0.0" (range)
  bool satisfies(String requirement) {
    requirement = requirement.trim();

    // Exact match
    if (!requirement.startsWith('^') &&
        !requirement.startsWith('~') &&
        !requirement.startsWith('>') &&
        !requirement.startsWith('<') &&
        !requirement.startsWith('=')) {
      final reqVersion = SemanticVersion.tryParse(requirement);
      return reqVersion != null && this == reqVersion;
    }

    // Caret (^) - compatible with major version
    if (requirement.startsWith('^')) {
      final reqVersion = SemanticVersion.tryParse(requirement.substring(1));
      if (reqVersion == null) return false;
      return major == reqVersion.major && this >= reqVersion;
    }

    // Tilde (~) - compatible with minor version
    if (requirement.startsWith('~')) {
      final reqVersion = SemanticVersion.tryParse(requirement.substring(1));
      if (reqVersion == null) return false;
      return major == reqVersion.major &&
          minor == reqVersion.minor &&
          this >= reqVersion;
    }

    // Greater than or equal
    if (requirement.startsWith('>=')) {
      final parts = requirement.split(' ').where((s) => s.isNotEmpty).toList();
      final minVersion = SemanticVersion.tryParse(parts[0].substring(2));
      if (minVersion == null) return false;

      if (!(this >= minVersion)) return false;

      // Check for upper bound
      if (parts.length > 1 && parts[1].startsWith('<')) {
        final maxVersion = SemanticVersion.tryParse(parts[1].substring(1));
        if (maxVersion != null && !(this < maxVersion)) return false;
      }

      return true;
    }

    // Greater than
    if (requirement.startsWith('>') && !requirement.startsWith('>=')) {
      final reqVersion = SemanticVersion.tryParse(requirement.substring(1));
      return reqVersion != null && this > reqVersion;
    }

    // Less than
    if (requirement.startsWith('<') && !requirement.startsWith('<=')) {
      final reqVersion = SemanticVersion.tryParse(requirement.substring(1));
      return reqVersion != null && this < reqVersion;
    }

    // Less than or equal
    if (requirement.startsWith('<=')) {
      final reqVersion = SemanticVersion.tryParse(requirement.substring(2));
      return reqVersion != null && this <= reqVersion;
    }

    return false;
  }
}

/// Dependency with version requirement
class ModuleDependency {
  final String moduleId;
  final String? versionRequirement;
  final bool isOptional;

  ModuleDependency({
    required this.moduleId,
    this.versionRequirement,
    this.isOptional = false,
  });

  /// Parse from string format: "module_id" or "module_id@^1.0.0"
  factory ModuleDependency.parse(String spec, {bool isOptional = false}) {
    if (spec.contains('@')) {
      final parts = spec.split('@');
      return ModuleDependency(
        moduleId: parts[0],
        versionRequirement: parts[1],
        isOptional: isOptional,
      );
    }
    return ModuleDependency(moduleId: spec, isOptional: isOptional);
  }

  /// Check if a version satisfies this dependency
  bool isSatisfiedBy(String version) {
    if (versionRequirement == null) return true;
    final semver = SemanticVersion.tryParse(version);
    return semver?.satisfies(versionRequirement!) ?? false;
  }

  @override
  String toString() {
    String result = moduleId;
    if (versionRequirement != null) result += '@$versionRequirement';
    if (isOptional) result += ' (optional)';
    return result;
  }
}

/// Result of dependency resolution
class DependencyResolutionResult {
  final bool success;
  final List<String> resolvedOrder;
  final List<String> errors;
  final List<String> warnings;

  DependencyResolutionResult({
    required this.success,
    this.resolvedOrder = const [],
    this.errors = const [],
    this.warnings = const [],
  });
}

/// Resolves module dependencies and determines load order
class DependencyResolver {
  /// Resolve dependencies and return load order
  /// Uses topological sort to determine correct order
  DependencyResolutionResult resolve({
    required Map<String, List<ModuleDependency>> modules,
    required Map<String, String> moduleVersions,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    final resolved = <String>[];
    final unresolved = <String>{};
    // Flag to stop resolution immediately when circular dependency is found
    bool hasCircularDependency = false;

    void resolveModule(String moduleId) {
      // Stop immediately if circular dependency was detected
      if (hasCircularDependency) return;
      if (resolved.contains(moduleId)) return;
      if (unresolved.contains(moduleId)) {
        errors.add('Circular dependency detected: $moduleId');
        hasCircularDependency = true;
        return;
      }

      unresolved.add(moduleId);

      final deps = modules[moduleId] ?? [];
      for (final dep in deps) {
        // Check before processing each dependency to exit early
        if (hasCircularDependency) return;

        // Check if dependency exists
        if (!modules.containsKey(dep.moduleId)) {
          if (dep.isOptional) {
            warnings.add('Optional dependency ${dep.moduleId} not found');
          } else {
            errors.add('Missing required dependency: ${dep.moduleId}');
          }
          continue;
        }

        // Check version compatibility
        final depVersion = moduleVersions[dep.moduleId];
        if (depVersion != null && !dep.isSatisfiedBy(depVersion)) {
          errors.add(
            'Version mismatch: ${dep.moduleId} requires ${dep.versionRequirement}, '
            'got $depVersion',
          );
          continue;
        }

        resolveModule(dep.moduleId);
      }

      unresolved.remove(moduleId);
      if (!hasCircularDependency) {
        resolved.add(moduleId);
      }
    }

    // Resolve all modules
    for (final moduleId in modules.keys) {
      if (hasCircularDependency) break;
      resolveModule(moduleId);
    }

    return DependencyResolutionResult(
      success: errors.isEmpty,
      resolvedOrder: resolved,
      errors: errors,
      warnings: warnings,
    );
  }
}
