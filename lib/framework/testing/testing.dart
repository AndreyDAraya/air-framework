import 'dart:async';
import 'package:flutter/foundation.dart';
import '../state/air.dart';
import '../communication/event_bus.dart';
import '../di/di.dart';
import '../security/secure_service_registry.dart';

/// Testing utilities for Air Framework modules.
///
/// Provides a clean, isolated environment for testing modules, state flows,
/// and inter-module communication.
///
/// Example:
/// ```dart
/// void main() {
///   testModule(
///     module: CartModule(),
///     initialState: {'cart.items': []},
///     test: (module, harness) async {
///       // Simulate adding an item
///       harness.emitSignal('cart.add', {'productId': '123'});
///
///       // Verify state changed
///       expect(harness.getState('cart.items'), hasLength(1));
///     },
///   );
/// }
/// ```

/// Test harness for Air modules
class AirTestHarness {
  final Map<String, dynamic> _initialState;
  final List<_EmittedEvent> _emittedEvents = [];
  final List<_EmittedSignal> _emittedSignals = [];

  /// Create a test harness with optional initial state
  AirTestHarness({Map<String, dynamic>? initialState})
    : _initialState = initialState ?? {};

  /// Setup the test environment
  void setup() {
    // Clear existing state
    _clearAll();

    // Set initial state
    for (final entry in _initialState.entries) {
      Air()
          .state(entry.key, initialValue: entry.value)
          .setValue(entry.value, sourceModuleId: 'test');
    }
  }

  /// Cleanup after test
  void teardown() {
    _clearAll();
    _emittedEvents.clear();
    _emittedSignals.clear();
  }

  void _clearAll() {
    // Only clear in debug mode
    if (kDebugMode) {
      Air().clear();
      EventBus().clearAll();
      AirDI().clear();
      SecureServiceRegistry().clearAll();
    }
  }

  /// Get current state value
  T? getState<T>(String key) {
    final controller = Air().debugStates[key];
    if (controller == null) return null;
    return controller.value as T?;
  }

  /// Set state value
  void setState<T>(String key, T value) {
    Air()
        .state<T>(key, initialValue: value)
        .setValue(value, sourceModuleId: 'test');
  }

  /// Emit a typed event
  void emit<T extends ModuleEvent>(T event) {
    EventBus().emit(event);
    _emittedEvents.add(_EmittedEvent(event.runtimeType, event));
  }

  /// Emit a named signal
  void emitSignal(String signalName, [dynamic data]) {
    EventBus().emitSignal(signalName, data: data, sourceModuleId: 'test');
    _emittedSignals.add(_EmittedSignal(signalName, data));
  }

  /// Subscribe to events and return received events
  List<T> captureEvents<T extends ModuleEvent>() {
    final events = <T>[];
    EventBus().on<T>((event) => events.add(event));
    return events;
  }

  /// Subscribe to signals and return received data
  List<dynamic> captureSignals(String signalName) {
    final signals = <dynamic>[];
    EventBus().onSignal(signalName, (data) => signals.add(data));
    return signals;
  }

  /// Get all emitted events of a type
  List<T> getEmittedEvents<T>() {
    return _emittedEvents
        .where((e) => e.type == T)
        .map((e) => e.event as T)
        .toList();
  }

  /// Get all emitted signals with a name
  List<dynamic> getEmittedSignals(String signalName) {
    return _emittedSignals
        .where((s) => s.name == signalName)
        .map((s) => s.data)
        .toList();
  }

  /// Register a mock service
  void registerMock<T>(T mock, {String? moduleId}) {
    AirDI().register<T>(
      mock,
      moduleId: moduleId ?? 'test',
      allowOverwrite: true,
    );
  }

  /// Wait for a condition to be true (with timeout)
  Future<void> waitFor(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 50),
  }) async {
    final startTime = DateTime.now();
    while (!condition()) {
      if (DateTime.now().difference(startTime) > timeout) {
        throw TimeoutException('Condition not met within timeout', timeout);
      }
      await Future.delayed(pollInterval);
    }
  }

  /// Wait for state to have a specific value
  Future<void> waitForState<T>(
    String key,
    T expectedValue, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await waitFor(() => getState<T>(key) == expectedValue, timeout: timeout);
  }

  /// Pump (process async events)
  Future<void> pump([
    Duration duration = const Duration(milliseconds: 10),
  ]) async {
    await Future.delayed(duration);
  }
}

class _EmittedEvent {
  final Type type;
  final dynamic event;
  _EmittedEvent(this.type, this.event);
}

class _EmittedSignal {
  final String name;
  final dynamic data;
  _EmittedSignal(this.name, this.data);
}

/// Test a module in isolation
///
/// Example:
/// ```dart
/// await testModule(
///   module: CartModule(),
///   initialState: {'cart.items': []},
///   test: (module, harness) async {
///     harness.emitSignal('cart.add', {'productId': '123'});
///     expect(harness.getState('cart.items'), hasLength(1));
///   },
/// );
/// ```
Future<void> testModule<M>({
  required M module,
  Map<String, dynamic> initialState = const {},
  required Future<void> Function(M module, AirTestHarness harness) test,
}) async {
  final harness = AirTestHarness(initialState: initialState);

  try {
    harness.setup();
    await test(module, harness);
  } finally {
    harness.teardown();
  }
}

/// Test an AirState in isolation
///
/// Example:
/// ```dart
/// await testState(
///   createState: () => CartState(),
///   initialState: {'cart.items': []},
///   test: (state, harness) async {
///     harness.emitSignal('cart.add', {'productId': '123'});
///     await harness.pump();
///     expect(harness.getState('cart.items'), hasLength(1));
///   },
/// );
/// ```
Future<void> testState<S extends AirState>({
  required S Function() createState,
  Map<String, dynamic> initialState = const {},
  required Future<void> Function(S state, AirTestHarness harness) test,
}) async {
  final harness = AirTestHarness(initialState: initialState);
  late S state;

  try {
    harness.setup();
    state = createState();
    await test(state, harness);
  } finally {
    state.dispose();
    harness.teardown();
  }
}

/// Matcher for checking state values
class StateMatcher {
  final String key;
  final AirTestHarness harness;

  StateMatcher(this.key, this.harness);

  /// Check if state equals expected value
  bool equals<T>(T expected) => harness.getState<T>(key) == expected;

  /// Check if state is null
  bool get isNull => harness.getState(key) == null;

  /// Check if state is not null
  bool get isNotNull => harness.getState(key) != null;

  /// Get the current value
  T? value<T>() => harness.getState<T>(key);
}

/// Extension for easier state assertions
extension AirTestHarnessMatchers on AirTestHarness {
  /// Get a state matcher for assertions
  StateMatcher stateOf(String key) => StateMatcher(key, this);
}
