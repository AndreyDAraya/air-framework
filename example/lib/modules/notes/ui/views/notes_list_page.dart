import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import '../../models/note.dart';
import '../state/state.dart';

/// Notes list page demonstrating reactive UI with AirView.
///
/// Shows:
/// - AirView for automatic reactivity when accessing flows
/// - Pull-to-refresh pattern
/// - Swipe to delete
/// - Search functionality
/// - Navigation with go_router
class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => NotesPulses.loadNotes.pulse(null),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: AirView((context) {
                  if (NotesFlows.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        NotesPulses.search.pulse('');
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ),
              onChanged: (value) => NotesPulses.search.pulse(value),
            ),
          ),

          // Notes list
          Expanded(
            child: AirView((context) {
              // Loading state
              if (NotesFlows.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error state
              final error = NotesFlows.error.value;
              if (error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error,
                        style: TextStyle(color: colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => NotesPulses.loadNotes.pulse(null),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // Get filtered notes
              final state = AirDI().get<NotesState>();
              final notes = state.filteredNotes;

              // Empty state
              if (notes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        NotesFlows.searchQuery.value.isNotEmpty
                            ? Icons.search_off
                            : Icons.note_add,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        NotesFlows.searchQuery.value.isNotEmpty
                            ? 'No notes found'
                            : 'No notes yet',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NotesFlows.searchQuery.value.isNotEmpty
                            ? 'Try a different search term'
                            : 'Tap + to create your first note',
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ],
                  ),
                );
              }

              // Notes grid
              return RefreshIndicator(
                onRefresh: () async {
                  NotesPulses.loadNotes.pulse(null);
                  // Wait a bit for the pulse to complete
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    return _NoteCard(note: notes[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }
}

/// Individual note card widget
class _NoteCard extends StatelessWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine text color based on note background
    final backgroundColor = isDark
        ? HSLColor.fromColor(note.color).withLightness(0.2).toColor()
        : note.color;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Note?'),
            content: Text('Are you sure you want to delete "${note.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        NotesPulses.deleteNote.pulse(note.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${note.title}" deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Re-add the note (simplified - in real app, store before delete)
                NotesPulses.loadNotes.pulse(null);
              },
            ),
          ),
        );
      },
      child: Card(
        color: backgroundColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/notes/${note.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and pin indicator
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned)
                      Icon(
                        Icons.push_pin,
                        size: 18,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Content preview
                Expanded(
                  child: Text(
                    note.content.isEmpty ? 'No content' : note.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Date
                Text(
                  _formatDate(note.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
