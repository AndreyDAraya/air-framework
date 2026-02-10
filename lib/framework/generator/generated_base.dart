import 'package:air_state/air_state.dart';
import '../communication/event_bus.dart';

/// Base class for generated state classes
/// INNOV-010: Code Generation Support
///
/// Extend this in your generated code:
/// ```dart
/// abstract class _CounterState extends GeneratedAirState {
///   _CounterState() : super('counter');
///   // Generated pulse handlers...
/// }
/// ```
abstract class GeneratedAirState extends AirState {
  /// Module ID for this state
  final String _generatedModuleId;

  GeneratedAirState(this._generatedModuleId)
    : super(moduleId: _generatedModuleId);

  /// Get the module ID
  @override
  String? get moduleId => _generatedModuleId;

  /// Override to register pulse handlers
  @override
  void onPulses();

  /// Helper to get typed state
  T getFlow<T>(AirStateKey<T> key) => Air().typedGet(key);

  /// Helper to set typed state
  void setFlow<T>(AirStateKey<T> key, T value) {
    Air().typedFlow(key, value, sourceModuleId: moduleId);
  }

  /// Helper to update typed state with a function
  void updateFlow<T>(AirStateKey<T> key, T Function(T current) updater) {
    final current = getFlow(key);
    setFlow(key, updater(current));
  }
}

/// Base class for generated module classes
///
/// Extend this in your generated code:
/// ```dart
/// abstract class _ShopModule extends GeneratedAppModule {
///   _ShopModule() : super('shop');
///   // Generated routes...
/// }
/// ```
abstract class GeneratedAppModule {
  /// Module ID
  final String moduleId;

  /// Whether this module is lazy loaded
  final bool isLazy;

  GeneratedAppModule(this.moduleId, {this.isLazy = false});

  /// Override to provide module routes
  List<dynamic> get routes => [];

  /// Override to provide module dependencies
  List<String> get dependencies => [];

  /// Called when module is initialized
  void onInit() {}

  /// Called when module is disposed
  void onDispose() {}
}

/// Base class for generated events
///
/// Extend this in your generated code:
/// ```dart
/// class OrderCreatedEvent extends GeneratedEvent {
///   final String orderId;
///   final double total;
///
///   OrderCreatedEvent({
///     required this.orderId,
///     required this.total,
///     required super.sourceModuleId,
///   });
/// }
/// ```
abstract class GeneratedEvent extends ModuleEvent {
  GeneratedEvent({required super.sourceModuleId});

  /// Convert event to map for serialization
  Map<String, dynamic> toMap();

  /// Create copy with modifications
  GeneratedEvent copyWith();
}

/// Mixin for automatic dependency injection
///
/// Use this with modules that need DI:
/// ```dart
/// class MyModule extends AppModule with GeneratedInjection {
///   @Inject() late AuthService auth;
///
///   @override
///   void injectDependencies() {
///     auth = inject<AuthService>();
///   }
/// }
/// ```
mixin GeneratedInjection {
  /// Override to inject dependencies
  void injectDependencies();

  /// Helper to get a dependency
  T inject<T>() {
    // Will be implemented by the DI system
    throw UnimplementedError('DI not configured');
  }

  /// Helper to get a dependency by key
  T injectByKey<T>(String key) {
    throw UnimplementedError('DI not configured');
  }
}

/// Registry for generated pulses
///
/// Used by generated code to register pulses:
/// ```dart
/// class CounterPulses {
///   static const increment = AirPulse<void>('counter.increment');
///   static void register() {
///     GeneratedPulsesRegistry.register('counter', [increment]);
///   }
/// }
/// ```
class GeneratedPulsesRegistry {
  static final Map<String, List<AirPulse>> _pulses = {};

  /// Register pulses for a module
  static void register(String moduleId, List<AirPulse> pulses) {
    _pulses[moduleId] = pulses;
  }

  /// Get all pulses for a module
  static List<AirPulse> getPulses(String moduleId) {
    return _pulses[moduleId] ?? [];
  }

  /// Get all registered module IDs
  static List<String> get moduleIds => _pulses.keys.toList();

  /// Clear registry (for testing)
  static void clear() {
    _pulses.clear();
  }
}

/// Registry for generated flows (state keys)
class GeneratedFlowsRegistry {
  static final Map<String, List<AirStateKey>> _flows = {};

  /// Register flows for a module
  static void register(String moduleId, List<AirStateKey> flows) {
    _flows[moduleId] = flows;
  }

  /// Get all flows for a module
  static List<AirStateKey> getFlows(String moduleId) {
    return _flows[moduleId] ?? [];
  }

  /// Get all registered module IDs
  static List<String> get moduleIds => _flows.keys.toList();

  /// Clear registry (for testing)
  static void clear() {
    _flows.clear();
  }
}
