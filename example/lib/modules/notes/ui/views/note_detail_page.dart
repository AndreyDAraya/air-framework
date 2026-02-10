import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import '../../models/note.dart';
import '../state/state.dart';

/// Note detail page for creating and editing notes.
///
/// Demonstrates:
/// - Route parameters with go_router
/// - Form handling with state management
/// - Color picker UI
/// - Conditional save behavior (create vs update)
class NoteDetailPage extends StatefulWidget {
  final String? noteId;

  const NoteDetailPage({super.key, this.noteId});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Color _selectedColor = NoteColors.palette.first;
  Note? _existingNote;
  bool _isLoading = true;

  bool get isNewNote => widget.noteId == null || widget.noteId == 'new';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (!isNewNote) {
      // Find existing note
      final state = AirDI().get<NotesState>();
      final notes = state.notes;
      try {
        _existingNote = notes.firstWhere((n) => n.id == widget.noteId);
        _titleController.text = _existingNote!.title;
        _contentController.text = _existingNote!.content;
        _selectedColor = _existingNote!.color;
      } catch (_) {
        // Note not found - will show error
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    if (isNewNote) {
      // Create new note
      NotesPulses.addNote.pulse((
        title: title,
        content: _contentController.text,
        color: _selectedColor,
      ));
    } else if (_existingNote != null) {
      // Update existing note
      final updated = _existingNote!.copyWith(
        title: title,
        content: _contentController.text,
        color: _selectedColor,
      );
      NotesPulses.updateNote.pulse(updated);
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Note not found
    if (!isNewNote && _existingNote == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              const Text('Note not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Compute background color
    final backgroundColor = isDark
        ? HSLColor.fromColor(_selectedColor).withLightness(0.15).toColor()
        : _selectedColor.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(isNewNote ? 'New Note' : 'Edit Note'),
        actions: [
          // Pin button (only for existing notes)
          if (!isNewNote && _existingNote != null)
            IconButton(
              icon: Icon(
                _existingNote!.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
              ),
              onPressed: () {
                NotesPulses.togglePin.pulse(_existingNote!.id);
                context.pop();
              },
              tooltip: _existingNote!.isPinned ? 'Unpin' : 'Pin',
            ),
          // Save button
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                filled: false,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),

            // Content input
            TextField(
              controller: _contentController,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Start writing...',
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
              minLines: 10,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Color picker
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: NoteColors.palette.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
