// ignore_for_file: unused_field
import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import '../../models/note.dart';
import '../../services/notes_repository.dart';

part 'state.air.g.dart';

/// Notes state management using Air Framework's code generation.
///
/// Demonstrates:
/// - @GenerateState annotation for automatic Flows and Pulses generation
/// - Private fields become reactive StateFlows
/// - Public methods become dispatchable Pulses
/// - Integration with services via AirDI
@GenerateState('notes')
class NotesState extends _NotesState {
  // ═══════════════════════════════════════════════════════════════════════════
  // STATE FLOWS (Private fields → automatically become reactive state)
  // ═══════════════════════════════════════════════════════════════════════════

  /// List of all notes
  final List<Note> _notes = [];

  /// Currently selected note for editing
  final Note? _selectedNote = null;

  /// Loading state for async operations
  final bool _isLoading = false;

  /// Error message if any operation fails
  final String? _error = null;

  /// Search query for filtering notes
  final String _searchQuery = '';

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    // Load notes when state is initialized
    loadNotes();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PULSES (Public methods → automatically become dispatchable actions)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load all notes from repository
  @override
  Future<void> loadNotes() async {
    isLoading = true;
    error = null;

    try {
      final repository = AirDI().get<NotesRepository>();
      final loadedNotes = await repository.getAllNotes();

      // Sort: pinned first, then by updated date
      loadedNotes.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

      notes = loadedNotes;
    } catch (e) {
      error = 'Failed to load notes: $e';
    } finally {
      isLoading = false;
    }
  }

  /// Add a new note
  @override
  Future<void> addNote(
      ({String title, String content, Color color}) input) async {
    if (input.title.trim().isEmpty) {
      error = 'Title cannot be empty';
      return;
    }

    isLoading = true;
    error = null;

    try {
      final repository = AirDI().get<NotesRepository>();
      final newNote = Note.create(
        title: input.title.trim(),
        content: input.content,
        color: input.color,
      );

      await repository.addNote(newNote);
      notes = [newNote, ...notes];
    } catch (e) {
      error = 'Failed to add note: $e';
    } finally {
      isLoading = false;
    }
  }

  /// Update an existing note
  @override
  Future<void> updateNote(Note updatedNote) async {
    isLoading = true;
    error = null;

    try {
      final repository = AirDI().get<NotesRepository>();
      await repository.updateNote(updatedNote);

      // Update local list
      final updatedList = notes.map((n) {
        return n.id == updatedNote.id ? updatedNote : n;
      }).toList();

      notes = updatedList;
      selectedNote = null;
    } catch (e) {
      error = 'Failed to update note: $e';
    } finally {
      isLoading = false;
    }
  }

  /// Delete a note by ID
  @override
  Future<void> deleteNote(String id) async {
    error = null;

    try {
      final repository = AirDI().get<NotesRepository>();
      await repository.deleteNote(id);
      notes = notes.where((n) => n.id != id).toList();
    } catch (e) {
      error = 'Failed to delete note: $e';
    }
  }

  /// Toggle pin status of a note
  @override
  Future<void> togglePin(String id) async {
    final note = notes.firstWhere((n) => n.id == id);
    final updated = note.copyWith(isPinned: !note.isPinned);
    await updateNote(updated);
  }

  /// Select a note for editing
  @override
  void selectNote(Note? note) {
    selectedNote = note;
  }

  /// Update search query
  @override
  void search(String query) {
    searchQuery = query;
  }

  /// Clear any error
  @override
  void clearError() {
    error = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED GETTERS (Use these in UI for filtered/derived data)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get filtered notes based on search query
  List<Note> get filteredNotes {
    if (searchQuery.isEmpty) return notes;

    final query = searchQuery.toLowerCase();
    return notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();
  }

  /// Get count statistics
  int get totalCount => notes.length;
  int get pinnedCount => notes.where((n) => n.isPinned).length;
}
