import 'package:air_framework/air_framework.dart';

/// Emitted by the Notes module whenever the notes collection changes.
///
/// Consumers (e.g. Dashboard) subscribe via EventBus to receive
/// an up-to-date summary without importing NotesState directly.
class NotesChangedEvent extends ModuleEvent {
  final int totalCount;
  final int pinnedCount;

  NotesChangedEvent({
    required super.sourceModuleId,
    required this.totalCount,
    required this.pinnedCount,
  });
}
