// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'state.dart';

// **************************************************************************
// AirStateGenerator
// **************************************************************************

/// Pulses for the Dashboard module
class DashboardPulses {
  DashboardPulses._();

  /// Pulse: updateUserName
  static const updateUserName = AirPulse<String>('dashboard.updateUserName');

  /// Pulse: incrementQuickActions
  static const incrementQuickActions =
      AirPulse<void>('dashboard.incrementQuickActions');

  /// Pulse: dismissTips
  static const dismissTips = AirPulse<void>('dashboard.dismissTips');
}

/// Flows for the Dashboard module
class DashboardFlows {
  DashboardFlows._();

  /// Flow: userName
  static const userName =
      SimpleStateKey<String>('dashboard.userName', defaultValue: '');

  /// Flow: quickActionsUsed
  static const quickActionsUsed =
      SimpleStateKey<int>('dashboard.quickActionsUsed', defaultValue: 0);

  /// Flow: tipsDismissed
  static const tipsDismissed =
      SimpleStateKey<bool>('dashboard.tipsDismissed', defaultValue: false);
}

/// Base class for DashboardState
abstract class _DashboardState extends AirState {
  _DashboardState() : super(moduleId: 'dashboard');

  /// Handle updateUserName pulse
  void updateUserName(String name);

  /// Handle incrementQuickActions pulse
  void incrementQuickActions();

  /// Handle dismissTips pulse
  void dismissTips();

  /// Get userName value
  String get userName => Air().typedGet(DashboardFlows.userName);

  /// Set userName value
  set userName(String value) =>
      Air().typedFlow(DashboardFlows.userName, value, sourceModuleId: moduleId);

  /// Get quickActionsUsed value
  int get quickActionsUsed => Air().typedGet(DashboardFlows.quickActionsUsed);

  /// Set quickActionsUsed value
  set quickActionsUsed(int value) =>
      Air().typedFlow(DashboardFlows.quickActionsUsed, value,
          sourceModuleId: moduleId);

  /// Get tipsDismissed value
  bool get tipsDismissed => Air().typedGet(DashboardFlows.tipsDismissed);

  /// Set tipsDismissed value
  set tipsDismissed(bool value) => Air()
      .typedFlow(DashboardFlows.tipsDismissed, value, sourceModuleId: moduleId);

  @override
  void onPulses() {
    on(DashboardPulses.updateUserName, (value, {onSuccess, onError}) async {
      try {
        updateUserName(value);
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(DashboardPulses.incrementQuickActions, (_, {onSuccess, onError}) async {
      try {
        incrementQuickActions();
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(DashboardPulses.dismissTips, (_, {onSuccess, onError}) async {
      try {
        dismissTips();
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
  }
}
