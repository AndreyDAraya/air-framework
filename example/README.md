# AirNotes Pro - Air Framework Example

A comprehensive example app demonstrating the capabilities of the **Air Framework** for building modular Flutter applications.

## 🚀 Getting Started

```bash
cd example2
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## 📱 Features Demonstrated

### 🧩 Modular Architecture

- **4 independent modules**: Dashboard, Notes, Weather, Shell
- Each module has its own routes, services, and state
- Clean separation of concerns

### ⚡ Reactive State Management

- `@GenerateState` annotation for automatic code generation
- `AirView` for fine-grained UI reactivity
- Flows (reactive state) and Pulses (actions)

### 💉 Dependency Injection

- `AirDI` for service registration
- Module lifecycle: `onBind` (sync) → `onInit` (async) → `onDispose`
- Lazy singleton pattern

### 🔄 Cross-Module Communication

- Dashboard consumes state from Notes and Weather modules
- `EventBus` for typed events (`WeatherUpdatedEvent`)
- Clean module boundaries

### 🛠️ DevTools

- Swipe down to open debug inspector
- View state, modules, DI registrations, and more

## 📂 Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # MaterialApp configuration
└── modules/
    ├── dashboard/         # Cross-module state consumption
    ├── notes/             # CRUD with persistence
    │   ├── models/
    │   ├── services/
    │   └── ui/
    ├── weather/           # Async API + EventBus
    │   ├── events/
    │   ├── models/
    │   ├── services/
    │   └── ui/
    └── shell/             # Navigation structure
```

## 🎯 Key Patterns

### State Definition

```dart
@GenerateState('notes')
class NotesState extends _NotesState {
  final List<Note> _notes = [];  // → NotesFlows.notes

  @override
  Future<void> loadNotes() async {  // → NotesPulses.loadNotes
    isLoading = true;
    notes = await repository.getAllNotes();
    isLoading = false;
  }
}
```

### Reactive UI

```dart
AirView((context) {
  if (NotesFlows.isLoading.value) {
    return CircularProgressIndicator();
  }
  return Text('${NotesFlows.notes.value.length} notes');
})
```

### Cross-Module Access

```dart
// In Dashboard, consume Weather state
final weather = WeatherFlows.currentWeather.value;
```

## 📚 Learn More

- [Air Framework Documentation](https://pub.dev/packages/air_framework)
- [Developer Guide](../doc/DEVELOPER_GUIDE.md)
