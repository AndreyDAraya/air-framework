import 'package:air_framework/air_framework.dart';

import 'services/notes_repository.dart';
import 'ui/state/state.dart';
import 'ui/views/note_detail_page.dart';
import 'ui/views/notes_list_page.dart';

/// Notes Module - Demonstrates CRUD operations with persistence.
///
/// Features showcased:
/// - Module lifecycle (onBind for sync registration, onInit for async setup)
/// - Dependency injection with AirDI
/// - Multiple routes with path parameters
/// - Service layer for data persistence
class NotesModule extends AppModule {
  @override
  String get id => 'notes';

  @override
  String get name => 'Notes';

  @override
  String get version => '1.0.0';

  @override
  String get initialRoute => '/notes';

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE - Demonstrates proper initialization pattern
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onBind(AirDI di) {
    // SYNC ONLY: Register dependencies
    // Services are registered but not initialized yet
    di.registerLazySingleton<NotesRepository>(() => NotesRepository());
    di.registerLazySingleton<NotesState>(() => NotesState());
  }

  @override
  Future<void> onInit(AirDI di) async {
    // ASYNC: Initialize heavy resources
    // This is where we do async setup like database connections
    final repository = di.get<NotesRepository>();
    await repository.init();

    // Initialize state (triggers onInit and loads data)
    di.get<NotesState>();
  }

  @override
  Future<void> onDispose(AirDI di) async {
    // Cleanup when module is unregistered
    di.unregisterModule(id);
    super.onDispose(di);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTES - Multiple routes with path parameters
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  List<AirRoute> get routes => [
        // List all notes
        AirRoute(
          path: '/notes',
          builder: (context, state) => const NotesListPage(),
        ),
        // View/Edit a specific note
        AirRoute(
          path: '/notes/:id',
          builder: (context, state) {
            final noteId = state.pathParameters['id'];
            return NoteDetailPage(noteId: noteId);
          },
        ),
        // Create new note
        AirRoute(
          path: '/notes/new',
          builder: (context, state) => const NoteDetailPage(noteId: null),
        ),
      ];
}
