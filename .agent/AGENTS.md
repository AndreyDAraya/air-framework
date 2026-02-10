# Air Framework

**A modular, reactive, and scalable framework for Flutter. Build industrial-grade apps with a decoupled architecture.**

> **💡 For detailed framework instructions, see the dedicated skill:** [`.agent/skills/fluttermodules/SKILL.md`](skills/fluttermodules/SKILL.md)

## What is this project?

Air is a development framework that brings enterprise-grade modularity to Flutter. It allows developers to:

- **Create apps from templates** in seconds (`air create my_app`)
- **Generate modules, screens, and state** with CLI commands
- **Build features as isolated modules** that communicate via **EventBus**
- **Manage state reactively** with **Air State** (@GenerateState)

## Quick start

```bash
# Create a new app
air create my_app --template=starter

# Generate a module
air generate module products

# Generate state (inside module)
cd lib/modules/products
air generate state

# Run the app
flutter run
```

## Project structure

```
lib/
├── modules/           # Feature modules
│   ├── auth/          # Authentication module
│   │   ├── auth_module.dart  # Module definition
│   │   ├── ui/
│   │   │   ├── views/        # UI Screens
│   │   │   └── state/        # Air State (Logic)
│   │   └── services/         # Business Logic
│   └── home/          # Home module
└── main.dart          # App Entry point (Register modules)
```

## Architecture

Each module extends `AppModule`:

```dart
class ProductsModule extends AppModule {
  @override
  String get id => 'products';

  @override
  List<AirRoute> get routes => [...];

  @override
  void onBind(AirDI di) {
     // Register dependencies
  }
}
```

Modules communicate via:

- **EventBus** - Typed events and named signals
- **AirDI** - Dependency Injection container
- **SecureServiceRegistry** - Shared services with permissions

## Code style

- **Dart 3.0+** with null safety
- **AirView** for reactive UI (avoids `setState`)
- **Unidirectional Data Flow**: State -> UI -> Pulses -> State
- **Decoupled Modules**: No direct imports between feature modules

## Development commands

```bash
# Check project health
air doctor

# Generate a screen
air g screen product_detail --module=products

# Generate a service
air g service product --module=products

# Generate state
air g state
```

## Key files to understand

- `lib/modules/*/ui/state/state.dart` - State Logic
- `lib/modules/*/ui/state/state.air.g.dart` - Generated Reactive Code
- `AppModule` -Base class for all modules
- `AirView` - Widget for reactive UI updates

## Common patterns

**Creating a module:**

```bash
air generate module my_feature
```

**Emitting an event:**

```dart
EventBus().emit(MyEvent(data: 'value'));
```

**Listening to an event:**

```dart
EventBus().on<MyEvent>((event) => handleEvent(event));
```

**Using Reactive State:**

```dart
AirView((context) => Text(Flows.count.value));
```

**Triggering an Action:**

```dart
Pulses.increment.pulse(null);
```

## Notes for AI agents

- **Read the skill first** - See [`.agent/skills/fluttermodules/SKILL.md`](skills/fluttermodules/SKILL.md)
- **Use the CLI** - Always generate code with `air` commands to ensure proper wiring
- **State Management** - Use `@GenerateState` and `AirView`. Do not use `ChangeNotifier` or `Bloc` unless explicitly requested.
- **Module Isolation** - Respect module boundaries. Use `EventBus` for cross-module communication.
