// ignore_for_file: unused_field
import 'package:air_framework/air_framework.dart';

import '../../../notes/events/events.dart';

part 'state.air.g.dart';

/// Dashboard state for local dashboard-specific data.
///
/// Note: Notes summary data is received via EventBus (NotesChangedEvent)
/// to demonstrate proper cross-module communication — no direct imports
/// of other modules' state classes.
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

  /// Notes count — updated reactively via NotesChangedEvent (EventBus)
  final int _notesCount = 0;

  /// Pinned notes count — updated reactively via NotesChangedEvent (EventBus)
  final int _pinnedNotesCount = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  EventSubscription? _notesSub;

  @override
  void onInit() {
    // Subscribe to notes changes — no direct import of NotesState needed.
    // Notes module emits NotesChangedEvent after every mutation.
    _notesSub = EventBus().on<NotesChangedEvent>(
      (event) {
        notesCount = event.totalCount;
        pinnedNotesCount = event.pinnedCount;
      },
      subscriberModuleId: 'dashboard',
    );
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    super.dispose();
  }

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
