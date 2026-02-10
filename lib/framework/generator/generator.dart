/// Air Framework Code Generation
/// INNOV-010: Generación de Código con Build Runner
///
/// This library provides annotations and base classes for code generation.
///
/// ## Quick Start
///
/// 1. Add dependencies to pubspec.yaml:
/// ```yaml
/// dev_dependencies:
///   build_runner: ^2.4.0
///   air_generator: ^1.0.0
/// ```
///
/// 2. Create a state with annotations:
/// ```dart
/// import 'package:air_framework/generator.dart';
///
/// part 'counter_state.g.dart';
///
/// @GenerateState('counter')
/// class CounterState extends _CounterState {
///   @Pulse()
///   void increment();
///
///   @Pulse()
///   void decrement();
///
///   @Flow()
///   int count = 0;
/// }
/// ```
///
/// 3. Run code generation:
/// ```bash
/// flutter pub run build_runner build
/// ```
///
/// ## Available Annotations
///
/// - `@GenerateState(moduleId)` - Mark a class as an Air state
/// - `@Pulse()` - Mark a method as a pulse/signal
/// - `@Flow()` - Mark a field as a reactive flow
/// - `@GenerateModule(moduleId)` - Mark a class as an Air module
/// - `@Route(path)` - Mark a method as a route
/// - `@GenerateEvent()` - Mark a class as an Air event
/// - `@Inject()` - Mark a field for dependency injection
/// - `@Computed(deps)` - Mark a getter as a computed state
library;

export 'annotations.dart';
export 'generated_base.dart';
