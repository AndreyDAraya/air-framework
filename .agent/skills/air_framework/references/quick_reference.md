# Air Quick Reference

## CLI Commands

| Command                  | Description         |
| ------------------------ | ------------------- |
| `create <name>`          | Create new project  |
| `generate module <name>` | Generate module     |
| `generate state`         | Generate state code |
| `doctor`                 | Check configuration |

## Module Interface

```dart
abstract class AppModule {
  String get id;
  String get name;
  List<AirRoute> get routes;
  List<String> get dependencies;
  void onBind(AirDI di);
  Future<void> onInit(AirDI di);
}
```

## Communication Patterns

```dart
// Typed Events
EventBus().emit(MyEvent());
EventBus().on<MyEvent>((e) => handle(e));

// Named Signals
EventBus().emitSignal('key', data: val);
EventBus().onSignal('key', (data) => ...);

// Reactive State
AirView((context) => Text(Flows.count.value));
Pulses.increment.pulse(null);
```

## Folder Structure

```
lib/
├── modules/        # Features (Auth, Home, etc.)
├── main.dart       # App Entry point
└── pubspec.yaml
```
