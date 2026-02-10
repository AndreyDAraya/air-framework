import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

/// Repository for persisting notes using SharedPreferences.
///
/// Demonstrates:
/// - Async initialization pattern
/// - Local persistence with JSON serialization
/// - CRUD operations
class NotesRepository {
  static const String _storageKey = 'air_notes_data';

  SharedPreferences? _prefs;

  /// Initialize the repository
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all saved notes
  Future<List<Note>> getAllNotes() async {
    _ensureInitialized();

    final jsonString = _prefs!.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If data is corrupted, return empty list
      return [];
    }
  }

  /// Save all notes
  Future<void> saveAllNotes(List<Note> notes) async {
    _ensureInitialized();

    final jsonList = notes.map((note) => note.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs!.setString(_storageKey, jsonString);
  }

  /// Add a new note
  Future<Note> addNote(Note note) async {
    final notes = await getAllNotes();
    notes.insert(0, note); // Add at beginning
    await saveAllNotes(notes);
    return note;
  }

  /// Update an existing note
  Future<Note?> updateNote(Note updatedNote) async {
    final notes = await getAllNotes();
    final index = notes.indexWhere((n) => n.id == updatedNote.id);

    if (index == -1) return null;

    notes[index] = updatedNote;
    await saveAllNotes(notes);
    return updatedNote;
  }

  /// Delete a note by ID
  Future<bool> deleteNote(String id) async {
    final notes = await getAllNotes();
    final initialLength = notes.length;
    notes.removeWhere((n) => n.id == id);

    if (notes.length == initialLength) return false;

    await saveAllNotes(notes);
    return true;
  }

  /// Clear all notes
  Future<void> clearAllNotes() async {
    _ensureInitialized();
    await _prefs!.remove(_storageKey);
  }

  /// Get note by ID
  Future<Note?> getNoteById(String id) async {
    final notes = await getAllNotes();
    try {
      return notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  void _ensureInitialized() {
    if (_prefs == null) {
      throw StateError('NotesRepository not initialized. Call init() first.');
    }
  }
}
