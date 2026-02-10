// ignore_for_file: unused_field
import 'package:air_framework/air_framework.dart';

part 'state.air.g.dart';

/// Dashboard state for local dashboard-specific data.
///
/// Note: The Dashboard module primarily consumes state from other modules
/// (Notes, Weather) rather than managing extensive state of its own.
/// This demonstrates cross-module state access patterns.
@GenerateState('dashboard')
class DashboardState extends _DashboardState {
  // ═══════════════════════════════════════════════════════════════════════════
  // STATE FLOWS - Dashboard-specific state
  // ═══════════════════════════════════════════════════════════════════════════

  /// User's display name (could come from a profile module)
  final String _userName = 'User';

  /// Quick actions count
  final int _quickActionsUsed = 0;

  /// Whether tips are dismissed
  final bool _tipsDismissed = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // PULSES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update user name
  @override
  void updateUserName(String name) {
    userName = name;
  }

  /// Increment quick actions counter
  @override
  void incrementQuickActions() {
    quickActionsUsed = quickActionsUsed + 1;
  }

  /// Dismiss tips section
  @override
  void dismissTips() {
    tipsDismissed = true;
  }
}
