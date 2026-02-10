/// Annotations for Air Framework code generation
/// INNOV-010: Generación de Código con Build Runner
///
/// These annotations are used with `air_generator` package to generate
/// boilerplate code for states, modules, and events.
///
/// ## Usage
///
/// 1. Add dependencies:
/// ```yaml
/// dev_dependencies:
///   build_runner: ^2.4.0
///   air_generator: ^1.0.0
/// ```
///
/// 2. Annotate your classes:
/// ```dart
/// part 'counter_state.g.dart';
///
/// @GenerateState('counter')
/// class CounterState extends _CounterState {
///   @Pulse() void increment();
///   @StateFlow() int count = 0;
/// }
/// ```
///
/// 3. Run code generation:
/// ```bash
/// dart run build_runner build
/// ```
library;

/// Annotation to mark a class as an Air state
///
/// This generates:
/// - Pulses class with all @Pulse methods as AirPulse constants
/// - Flows class with all @StateFlow fields as AirStateKey constants
/// - Base class extending AirState with onPulses() implementation
///
/// Example:
/// ```dart
/// @GenerateState('counter')
/// class CounterState extends _CounterState {
///   @Pulse() void increment();
///   @Pulse() void decrement();
///   @StateFlow() int count = 0;
/// }
/// ```
class GenerateState {
  /// Module ID for this state
  final String moduleId;

  /// Whether to generate typed getters/setters for flows
  final bool generateAccessors;

  /// Whether to include documentation in generated code
  final bool includeDocs;

  const GenerateState(
    this.moduleId, {
    this.generateAccessors = true,
    this.includeDocs = true,
  });
}

/// Annotation to mark a method as a pulse (signal/action)
///
/// The method signature determines the pulse parameters.
/// Return type should be void.
///
/// Example:
/// ```dart
/// @Pulse()
/// void addItem(String productId, int quantity);
/// // Generates: AirPulse<({String productId, int quantity})>('module.addItem')
/// ```
class Pulse {
  /// Custom pulse name (defaults to method name)
  final String? name;

  /// Description for documentation
  final String? description;

  const Pulse({this.name, this.description});
}

/// Annotation to mark a field as a flow (reactive state)
///
/// The field type and default value are used to generate an AirStateKey.
/// IMPORTANT: Named 'StateFlow' to avoid conflict with Flutter's Flow widget.
///
/// Example:
/// ```dart
/// @StateFlow()
/// List<CartItem> items = [];
/// // Generates: AirStateKey<List<CartItem>>('module.items', defaultValue: [])
/// ```
class StateFlow {
  /// Custom flow name (defaults to field name)
  final String? name;

  /// Whether this flow should be persisted
  final bool persist;

  /// Description for documentation
  final String? description;

  const StateFlow({this.name, this.persist = false, this.description});
}

/// Annotation to mark a class as an Air module
///
/// Generates module structure with routes and dependencies.
///
/// Example:
/// ```dart
/// @GenerateModule('shop')
/// class ShopModule extends _ShopModule {
///   @Route('/shop') Widget shopScreen();
///   @Route('/shop/:id') Widget productDetail(String id);
/// }
/// ```
class GenerateModule {
  /// Module ID
  final String moduleId;

  /// Optional module name
  final String? name;

  /// Optional module version
  final String? version;

  /// Optional initial route
  final String? initialRoute;

  /// Module dependencies (other module IDs)
  final List<String> dependencies;

  /// Whether this module should be lazy loaded
  final bool lazy;

  const GenerateModule(
    this.moduleId, {
    this.name,
    this.version,
    this.initialRoute,
    this.dependencies = const [],
    this.lazy = false,
  });
}

/// Annotation to mark a method as a route
///
/// Used within @AirModule to define navigation routes.
///
/// Example:
/// ```dart
/// @Route('/products/:id')
/// Widget productDetail(String id);
/// ```
class Route {
  /// Route path (can include parameters like :id)
  final String path;

  /// Route name for named navigation
  final String? name;

  /// Whether this route requires authentication
  final bool requiresAuth;

  const Route(this.path, {this.name, this.requiresAuth = false});
}

/// Annotation to mark a class as an Air event
///
/// Generates a typed event class that extends ModuleEvent.
///
/// Example:
/// ```dart
/// @GenerateEvent()
/// class OrderCreated {
///   final String orderId;
///   final double total;
/// }
/// // Generates: class OrderCreatedEvent extends ModuleEvent { ... }
/// ```
class GenerateEvent {
  /// Custom event name (defaults to class name)
  final String? name;

  const GenerateEvent({this.name});
}

/// Annotation to inject a dependency
///
/// Used to mark fields for automatic dependency injection.
///
/// Example:
/// ```dart
/// @Inject()
/// late AuthService authService;
///
/// @Inject('custom_key')
/// late ApiClient api;
/// ```
class Inject {
  /// Custom key for DI lookup (defaults to type)
  final String? key;

  const Inject([this.key]);
}

/// Annotation to mark a computed state
///
/// Generates a ComputedState that depends on other flows.
///
/// Example:
/// ```dart
/// @Computed(['cart.items', 'cart.discount'])
/// double get total => _computeTotal();
/// ```
class Computed {
  /// State keys this computed depends on
  final List<String> dependencies;

  const Computed(this.dependencies);
}
