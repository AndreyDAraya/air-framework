// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'state.dart';

// **************************************************************************
// AirStateGenerator
// **************************************************************************

/// Pulses for the Notes module
class NotesPulses {
  NotesPulses._();

  /// Pulse: loadNotes
  static const loadNotes = AirPulse<void>('notes.loadNotes');

  /// Pulse: addNote
  static const addNote =
      AirPulse<({Color color, String content, String title})>('notes.addNote');

  /// Pulse: updateNote
  static const updateNote = AirPulse<Note>('notes.updateNote');

  /// Pulse: deleteNote
  static const deleteNote = AirPulse<String>('notes.deleteNote');

  /// Pulse: togglePin
  static const togglePin = AirPulse<String>('notes.togglePin');

  /// Pulse: selectNote
  static const selectNote = AirPulse<Note?>('notes.selectNote');

  /// Pulse: search
  static const search = AirPulse<String>('notes.search');

  /// Pulse: clearError
  static const clearError = AirPulse<void>('notes.clearError');
}

/// Flows for the Notes module
class NotesFlows {
  NotesFlows._();

  /// Flow: notes
  static const notes =
      SimpleStateKey<List<Note>>('notes.notes', defaultValue: []);

  /// Flow: selectedNote
  static const selectedNote =
      SimpleStateKey<Note?>('notes.selectedNote', defaultValue: null);

  /// Flow: isLoading
  static const isLoading =
      SimpleStateKey<bool>('notes.isLoading', defaultValue: false);

  /// Flow: error
  static const error = SimpleStateKey<String?>('notes.error', defaultValue: '');

  /// Flow: searchQuery
  static const searchQuery =
      SimpleStateKey<String>('notes.searchQuery', defaultValue: '');
}

/// Base class for NotesState
abstract class _NotesState extends AirState {
  _NotesState() : super(moduleId: 'notes');

  /// Handle loadNotes pulse
  Future<void> loadNotes();

  /// Handle addNote pulse
  Future<void> addNote(({Color color, String content, String title}) input);

  /// Handle updateNote pulse
  Future<void> updateNote(Note updatedNote);

  /// Handle deleteNote pulse
  Future<void> deleteNote(String id);

  /// Handle togglePin pulse
  Future<void> togglePin(String id);

  /// Handle selectNote pulse
  void selectNote(Note? note);

  /// Handle search pulse
  void search(String query);

  /// Handle clearError pulse
  void clearError();

  /// Get notes value
  List<Note> get notes => Air().typedGet(NotesFlows.notes);

  /// Set notes value
  set notes(List<Note> value) =>
      Air().typedFlow(NotesFlows.notes, value, sourceModuleId: moduleId);

  /// Get selectedNote value
  Note? get selectedNote => Air().typedGet(NotesFlows.selectedNote);

  /// Set selectedNote value
  set selectedNote(Note? value) =>
      Air().typedFlow(NotesFlows.selectedNote, value, sourceModuleId: moduleId);

  /// Get isLoading value
  bool get isLoading => Air().typedGet(NotesFlows.isLoading);

  /// Set isLoading value
  set isLoading(bool value) =>
      Air().typedFlow(NotesFlows.isLoading, value, sourceModuleId: moduleId);

  /// Get error value
  String? get error => Air().typedGet(NotesFlows.error);

  /// Set error value
  set error(String? value) =>
      Air().typedFlow(NotesFlows.error, value, sourceModuleId: moduleId);

  /// Get searchQuery value
  String get searchQuery => Air().typedGet(NotesFlows.searchQuery);

  /// Set searchQuery value
  set searchQuery(String value) =>
      Air().typedFlow(NotesFlows.searchQuery, value, sourceModuleId: moduleId);

  @override
  void onPulses() {
    on(NotesPulses.loadNotes, (_, {onSuccess, onError}) async {
      try {
        await loadNotes();
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(NotesPulses.addNote, (value, {onSuccess, onError}) async {
      try {
        await addNote(value);
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(NotesPulses.updateNote, (value, {onSuccess, onError}) async {
      try {
        await updateNote(value);
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(NotesPulses.deleteNote, (value, {onSuccess, onError}) async {
      try {
        await deleteNote(value);
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(NotesPulses.togglePin, (value, {onSuccess, onError}) async {
      try {
        await togglePin(value);
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(NotesPulses.selectNote, (value, {onSuccess, onError}) async {
      try {
        selectNote(value);
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(NotesPulses.search, (value, {onSuccess, onError}) async {
      try {
        search(value);
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
    on(NotesPulses.clearError, (_, {onSuccess, onError}) async {
      try {
        clearError();
        onSuccess?.call();
      } catch (e) {
        onError?.call(e.toString());
      }
    });
  }
}
