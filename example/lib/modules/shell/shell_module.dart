import 'package:air_framework/air_framework.dart';

import '../notes/ui/views/note_detail_page.dart';
import '../notes/ui/views/notes_list_page.dart';
import '../weather/ui/views/weather_page.dart';
import 'ui/views/shell_page.dart';

/// Shell Module - Provides the main navigation structure.
///
/// Features showcased:
/// - ShellRoute pattern with go_router
/// - Bottom navigation bar
/// - Nested routes
/// - Persistent layout across navigation
class ShellModule extends AppModule {
  @override
  String get id => 'shell';

  @override
  String get name => 'Shell';

  @override
  String get version => '1.0.0';

  @override
  String get initialRoute => '/shell';

  @override
  void onBind(AirDI di) {
    // Shell module doesn't need DI registrations
  }

  @override
  Future<void> onInit(AirDI di) async {
    // No async initialization needed
  }

  @override
  List<AirRoute> get routes => [
        // Shell route with nested navigation
        AirRoute(
          path: '/shell',
          builder: (context, state) => const ShellPage(),
          routes: [
            // Notes list
            AirRoute(
              path: 'notes',
              builder: (context, state) => const NotesListPage(),
            ),
            // Note detail (nested under shell)
            AirRoute(
              path: 'notes/:id',
              builder: (context, state) {
                final noteId = state.pathParameters['id'];
                return NoteDetailPage(noteId: noteId);
              },
            ),
            // Weather
            AirRoute(
              path: 'weather',
              builder: (context, state) => const WeatherPage(),
            ),
          ],
        ),
      ];
}
