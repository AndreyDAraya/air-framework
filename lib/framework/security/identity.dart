import 'dart:math';

/// A token that identifies a module and proves its identity to other modules.
///
/// This token is granted by the [ModuleManager] during the module's initialization
/// lifecycle. It is used to sign signals and verify that the sender is indeed
/// the module they claim to be.
class ModuleIdentityToken {
  final String moduleId;
  final String _secret;
  final DateTime issuedAt;

  ModuleIdentityToken._(this.moduleId, this._secret, this.issuedAt);

  /// Create a new identity token (Internal use only)
  factory ModuleIdentityToken.issue(String moduleId) {
    final random = Random.secure();
    final secret = List.generate(
      32,
      (_) => random.nextInt(256),
    ).map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return ModuleIdentityToken._(moduleId, secret, DateTime.now());
  }

  /// Verify if the token matches the expected module ID
  bool verify(String expectedModuleId) {
    return moduleId == expectedModuleId;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleIdentityToken &&
          runtimeType == other.runtimeType &&
          moduleId == other.moduleId &&
          _secret == other._secret;

  @override
  int get hashCode => moduleId.hashCode ^ _secret.hashCode;
}
