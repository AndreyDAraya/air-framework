---
name: air_framework
description: Create modular Flutter apps with the Air framework. Use this skill when building Flutter apps with modular architecture, generating modules, screens, services, or scaffolding new projects.
---

# Air Framework

A modular, reactive, and scalable framework for Flutter. Build industrial-grade apps with a decoupled architecture.

## When to use this skill

Use this skill when the user needs to:

- Create a new Flutter app with modular architecture
- Generate modules, screens, services, or reactive states
- Understand how modules communicate via EventBus (Events & Signals)
- Set up authentication, routing (go_router), or state management (Air State) in a modular way
- Debug or refactor existing Air Framework modules

## Core Concepts

### Modules

Every feature is a module. A module is a self-contained unit that includes its own logic, UI, routes, and dependencies.

### Module Structure

```
lib/modules/products/
├── products_module.dart      # Module definition (extends AppModule)
├── ui/
│   ├── views/                # Screen files
│   │   └── product_list_view.dart
│   └── state/                # Reactive State (Architecture)
│       ├── state.dart        # State Logic (@GenerateState)
│       ├── state.air.g.dart  # Generated Code (Flows & Pulses)
│       └── products.dart     # Models
├── services/                 # Business logic interfaces & implementations
├── repositories/             # Data access layer
└── widgets/                  # Reusable UI components
```

### Module Definition

Modules must extend `AppModule`.

```dart
import 'package:air_framework/air_framework.dart';

class ProductsModule extends AppModule {
  @override
  String get id => 'products';

  @override
  String get name => 'Products'; // Optional

  @override
  List<AirRoute> get routes => [
    AirRoute(
      path: '/products',
      builder: (context, state) => const ProductListView(),
    ),
  ];

  @override
  List<String> get dependencies => ['auth:^1.0.0']; // Explicit dependencies

  @override
  void onBind(AirDI di) {
     // Register dependencies (Sync)
     di.registerLazySingleton<ProductState>(() => ProductState());
  }

  @override
  Future<void> onInit(AirDI di) async {
    // Async initialization
  }
}
```

## State Management (Air State)

### Defining State

Use `@GenerateState` to create reactive state. Private fields become `Flows` (reactive), public methods become `Pulses` (actions).

```dart
@GenerateState('products')
class ProductState extends _ProductState {
  // Flows (Reactive)
  List<Product> _items = [];
  bool _isLoading = false;

  // Pulses (Actions)
  @override
  Future<void> fetchProducts() async {
    isLoading = true;
    items = await _api.getProducts();
    isLoading = false;
  }
}
```

### Using State (AirView)

Use `AirView` to listen to state changes. It automatically tracks which `Flows` are accessed.

```dart
AirView((context) {
  if (ProductFlows.isLoading.value) {
    return const CircularProgressIndicator();
  }
  return ListView(children: ProductFlows.items.value.map((e) => Text(e.name)).toList());
});
// Trigger Action
ProductPulses.fetchProducts.pulse(null);
```

## Communication (EventBus)

Decouple modules using the Event Bus.

### Typed Events

```dart
// Define
class ProductSelectedEvent extends ModuleEvent {
  final Product product;
  ProductSelectedEvent({required super.sourceModuleId, required this.product});
}

// Emit
EventBus().emit(ProductSelectedEvent(sourceModuleId: 'products', product: p));

// Listen
EventBus().on<ProductSelectedEvent>((event) {
  print(event.product.name);
}, subscriberModuleId: 'cart');
```

### Named Signals (Loose coupling)

```dart
EventBus().emitSignal('cart.updated', data: {'count': 5}, sourceModuleId: 'cart');

EventBus().onSignal('cart.updated', (data) {
   // Handle signal
}, subscriberModuleId: 'header');
```

## CLI Commands (air)

```bash
# Create State
air generate state

# Create Module
air generate module name

# Create App
air create my_app
```

## Best Practices

1. **One module per feature**: Keep features isolated.
2. **Explicit Dependencies**: Declare them in `AppModule.dependencies`.
3. **Uni-directional Flow**: Data flows down (State -> UI), Actions flow up (UI -> Pulses -> State).
4. **Use internal go_router**: Leverage `AirRoute` for deep linking and navigation.
5. **Secure Services**: Use `SecureServiceRegistry` for sensitive operations.
