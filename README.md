# Air Framework 🚀

<p align="center">
  <img src="doc/assets/air-aero.svg" width="200" alt="Air Framework Logo" />
</p>

[![pub package](https://img.shields.io/pub/v/air_framework.svg?style=flat-square&color=blue)](https://pub.dev/packages/air_framework)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg?style=flat-square)](https://pub.dev/packages/flutter_lints)
[![docs](https://img.shields.io/badge/docs-air--framework.flutter.md-blue?style=flat-square)](https://air-framework.flutter.md/)

A **modular**, **reactive**, and **scalable** framework for Flutter. Build industrial-grade apps with a decoupled architecture inspired by enterprise app concepts.

> **Why Air Framework?**
>
> As apps grow, they become harder to maintain. Air Framework solves this by enforcing **strict module boundaries**, **unidirectional data flow**, and **explicit dependencies**. It's not just a state management library; it's a complete architecture for teams building large-scale Flutter applications.

---

## ✨ Features

| Feature                     | Description                                                             |
| --------------------------- | ----------------------------------------------------------------------- |
| 🧩 **Modular Architecture** | Self-contained, independent modules with clear boundaries               |
| 🔌 **Adapters**             | Headless service integrations (HTTP, analytics, error tracking)         |
| ⚡ **Reactive State**       | Built-in state management using `Air State` controller with typed flows |
| 💉 **Dependency Injection** | Type-safe DI with scoped services and lifecycle management              |
| 🔒 **Security**             | Permission system, secure logging, and audit trails                     |
| 🛣️ **Routing**              | Integrated routing with `go_router` support                             |
| 🛠️ **DevTools**             | Built-in debugging panels for state, modules, adapters, and performance |
| 🧪 **Testing Utilities**    | Mock controllers and test helpers included                              |

---

## 🏗️ Architecture

Every feature is a **Module**. Modules declare their dependencies explicitly and communicate via a typed **Event Bus**.

```
App Shell
├── Notes Module
├── Weather Module
└── Dashboard Module
    ├── depends on → Notes
    └── depends on → Weather

Core Framework
├── AirDI          (Dependency Injection)
├── AirRouter      (Routing)
├── EventBus       (Cross-module communication)
├── AirState       (Reactive state management)
├── AdapterManager (Infrastructure services)
└── DevTools       (Debugging inspector)
```

---

## 📦 Installation

Add `air_framework` to your `pubspec.yaml`:

```yaml
dependencies:
  air_framework: # latest version from pub.dev
```

For the complete development experience, also install the CLI:

```bash
dart pub global activate air_cli
```

---

## 🚀 Quick Start

### 1. Create a Module

Define a module by extending `AppModule`. This encapsulates your routes, bindings, and initialization logic.

```dart
import 'package:air_framework/air_framework.dart';

class CounterModule extends AppModule {
  @override
  String get id => 'counter';

  @override
  List<AirRoute> get routes => [
    AirRoute(
      path: '/counter',
      builder: (context, state) => const CounterPage(),
    ),
  ];

  @override
  void onBind(AirDI di) {
    super.onBind(di);
    // Register dependencies lazily
    di.registerLazySingleton<CounterState>(() => CounterState());
  }
}
```

### 2. Define State

Use the `@GenerateState` annotation to **magically** generate reactive `Flows` and `Pulses`.

Simply modify fields like a standard Dart class (e.g. `count++`), and the framework **automatically detects the change** and updates only the widgets listening to that value. No boilerplate, no `notifyListeners()`—just pure logic.

```dart
import 'package:air_framework/air_framework.dart';

part 'state.air.g.dart';

@GenerateState('counter')
class CounterState extends _CounterState {
  // Private fields become reactive StateFlows
  int _count = 0;

  // Public methods become dispatchable Pulses
  @override
  void increment() {
    count++;
  }
}
```

### 3. Build Reactive UI

Use `AirView` to listen to state changes efficiently. It automatically tracks which flows are accessed and rebuilds only when necessary.

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AirView((context) {
          // Auto-subscribes to 'count'
          return Text('Count: ${CounterFlows.count.value}');
        }),
      ),
      floatingActionButton: FloatingActionButton(
        // Triggers the 'increment' pulse
        onPressed: () => CounterPulses.increment.pulse(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 4. Initialize Your App

Register your modules in `main.dart`.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Configure Air State
  configureAirState();

  // 2. Register Adapters (infrastructure — BEFORE modules)
  final adapters = AdapterManager();
  await adapters.register(DioAdapter(baseUrl: 'https://api.example.com'));

  // 3. Register Modules (features — can use adapter services)
  await ModuleManager().register(CounterModule());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Air App',
      routerConfig: AirRouter().router,
    );
  }
}
```

---

## 🔌 Adapters

**Adapters** are headless service integrations. Unlike modules, they have no routes or UI — they register infrastructure services (HTTP clients, error tracking, analytics) in `AirDI` for modules to consume.

```dart
class SentryAdapter extends AirAdapter {
  @override
  String get id => 'sentry';

  @override
  void onBind(AirDI di) {
    super.onBind(di);
    // Register the abstract contract, not the concrete class
    di.registerLazySingleton<ErrorReporter>(() => SentryReporter());
  }
}
```

**Key rule:** every adapter must expose an **abstract contract** so modules never couple to a specific library.

```
lib/adapters/<service>/
├── contracts/
│   ├── <service>_client.dart     ← abstract interface
│   └── <service>_response.dart
├── <service>_adapter.dart         ← AirAdapter subclass
└── <service>_impl.dart            ← concrete implementation
```

Generate with the CLI: `air g adapter sentry`

---

## 🔧 CLI Tools

The **Air CLI** allows you to scaffold modules and generate state files instantly.

```bash
# Create a new project
air create my_app --template=starter

# Generate a new module
air generate module inventory

# Generate an adapter
air generate adapter sentry

# Generate state code
air generate state cart --module=inventory
```

---

## 📚 Related Packages

| Package                                                 | Description                   |
| ------------------------------------------------------- | ----------------------------- |
| [air_cli](https://pub.dev/packages/air_cli)             | Command-line scaffolding tool |
| [air_state](https://pub.dev/packages/air_state)         | Core reactive state package   |
| [air_generator](https://pub.dev/packages/air_generator) | Build runner code generation  |

---

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](https://github.com/AndreyDAraya/air-framework/blob/main/CONTRIBUTING.md) first.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📖 Documentation

For the full documentation, guides, and API reference visit:

👉 **[air-framework.flutter.md](https://air-framework.flutter.md/)**

---

Made by [Andrey D. Araya](https://github.com/AndreyDAraya)
