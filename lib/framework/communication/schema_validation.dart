import 'package:flutter/foundation.dart';
import '../security/air_logger.dart';
import 'event_bus.dart';

/// Schema validation for events
/// MEJORA-014: Validación de Schemas
///
/// Validates event data structure before processing.
///
/// Example:
/// ```dart
/// // Define a schema
/// final userCreatedSchema = MapSchema({
///   'id': StringSchema(required: true),
///   'email': StringSchema(required: true, pattern: r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
///   'age': NumberSchema(min: 0, max: 150),
/// });
///
/// // Register with EventBus
/// EventSchemaValidator().registerSchema<UserCreatedEvent>(userCreatedSchema);
///
/// // Now events are validated before emission
/// ```

/// Base class for schema validators
abstract class EventSchema<T> {
  /// Validate the event data
  bool validate(T data);

  /// Get validation errors
  List<String> getErrors(T data);
}

/// Schema for string values
class StringSchema implements EventSchema<String?> {
  final bool required;
  final int? minLength;
  final int? maxLength;
  final String? pattern;

  const StringSchema({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.pattern,
  });

  @override
  bool validate(String? value) => getErrors(value).isEmpty;

  @override
  List<String> getErrors(String? value) {
    final errors = <String>[];

    if (value == null || value.isEmpty) {
      if (required) errors.add('Value is required');
      return errors;
    }

    if (minLength != null && value.length < minLength!) {
      errors.add('Minimum length is $minLength');
    }

    if (maxLength != null && value.length > maxLength!) {
      errors.add('Maximum length is $maxLength');
    }

    if (pattern != null && !RegExp(pattern!).hasMatch(value)) {
      errors.add('Value does not match pattern');
    }

    return errors;
  }
}

/// Schema for numeric values
class NumberSchema implements EventSchema<num?> {
  final bool required;
  final num? min;
  final num? max;

  const NumberSchema({this.required = false, this.min, this.max});

  @override
  bool validate(num? value) => getErrors(value).isEmpty;

  @override
  List<String> getErrors(num? value) {
    final errors = <String>[];

    if (value == null) {
      if (required) errors.add('Value is required');
      return errors;
    }

    if (min != null && value < min!) {
      errors.add('Minimum value is $min');
    }

    if (max != null && value > max!) {
      errors.add('Maximum value is $max');
    }

    return errors;
  }
}

/// Schema for boolean values
class BoolSchema implements EventSchema<bool?> {
  final bool required;

  const BoolSchema({this.required = false});

  @override
  bool validate(bool? value) => getErrors(value).isEmpty;

  @override
  List<String> getErrors(bool? value) {
    if (value == null && required) {
      return ['Value is required'];
    }
    return [];
  }
}

/// Schema for list values
class ListSchema<T> implements EventSchema<List<T>?> {
  final bool required;
  final int? minItems;
  final int? maxItems;
  final EventSchema<T>? itemSchema;

  const ListSchema({
    this.required = false,
    this.minItems,
    this.maxItems,
    this.itemSchema,
  });

  @override
  bool validate(List<T>? value) => getErrors(value).isEmpty;

  @override
  List<String> getErrors(List<T>? value) {
    final errors = <String>[];

    if (value == null) {
      if (required) errors.add('List is required');
      return errors;
    }

    if (minItems != null && value.length < minItems!) {
      errors.add('Minimum $minItems items required');
    }

    if (maxItems != null && value.length > maxItems!) {
      errors.add('Maximum $maxItems items allowed');
    }

    if (itemSchema != null) {
      for (int i = 0; i < value.length; i++) {
        final itemErrors = itemSchema!.getErrors(value[i]);
        for (final error in itemErrors) {
          errors.add('Item [$i]: $error');
        }
      }
    }

    return errors;
  }
}

/// Schema for map/object values
class MapSchema implements EventSchema<Map<String, dynamic>?> {
  final bool required;
  final Map<String, EventSchema> properties;
  final bool additionalProperties;

  const MapSchema(
    this.properties, {
    this.required = false,
    this.additionalProperties = true,
  });

  @override
  bool validate(Map<String, dynamic>? value) => getErrors(value).isEmpty;

  @override
  List<String> getErrors(Map<String, dynamic>? value) {
    final errors = <String>[];

    if (value == null) {
      if (required) errors.add('Object is required');
      return errors;
    }

    for (final entry in properties.entries) {
      final propValue = value[entry.key];
      final propErrors = entry.value.getErrors(propValue);
      for (final error in propErrors) {
        errors.add('${entry.key}: $error');
      }
    }

    if (!additionalProperties) {
      for (final key in value.keys) {
        if (!properties.containsKey(key)) {
          errors.add('Unknown property: $key');
        }
      }
    }

    return errors;
  }
}

/// Validator that registers and validates event schemas
class EventSchemaValidator {
  static final EventSchemaValidator _instance = EventSchemaValidator._();
  factory EventSchemaValidator() => _instance;
  EventSchemaValidator._();

  final Map<Type, EventSchema> _schemas = {};
  final Map<String, EventSchema> _signalSchemas = {};
  bool _enabled = true;

  /// Enable schema validation
  void enable() => _enabled = true;

  /// Disable schema validation
  void disable() => _enabled = false;

  /// Check if validation is enabled
  bool get isEnabled => _enabled;

  /// Register a schema for a typed event
  void registerSchema<T extends ModuleEvent>(EventSchema schema) {
    _schemas[T] = schema;
    AirLogger.debug('Registered schema for ${T.toString()}');
  }

  /// Register a schema for a signal
  void registerSignalSchema(String signalName, EventSchema schema) {
    _signalSchemas[signalName] = schema;
    AirLogger.debug('Registered schema for signal "$signalName"');
  }

  /// Validate an event
  ValidationResult validateEvent<T extends ModuleEvent>(T event) {
    if (!_enabled) return ValidationResult.success();

    final schema = _schemas[T];
    if (schema == null) return ValidationResult.success();

    try {
      final errors = schema.getErrors(event);
      if (errors.isEmpty) {
        return ValidationResult.success();
      }
      return ValidationResult.failure(errors);
    } catch (e) {
      return ValidationResult.failure(['Validation error: $e']);
    }
  }

  /// Validate signal data
  ValidationResult validateSignal(String signalName, dynamic data) {
    if (!_enabled) return ValidationResult.success();

    final schema = _signalSchemas[signalName];
    if (schema == null) return ValidationResult.success();

    try {
      final errors = schema.getErrors(data);
      if (errors.isEmpty) {
        return ValidationResult.success();
      }
      return ValidationResult.failure(errors);
    } catch (e) {
      return ValidationResult.failure(['Validation error: $e']);
    }
  }

  /// Clear all registered schemas (for testing)
  @visibleForTesting
  void clear() {
    if (!kDebugMode) return;
    _schemas.clear();
    _signalSchemas.clear();
  }
}

/// Result of schema validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult._(this.isValid, this.errors);

  factory ValidationResult.success() => ValidationResult._(true, []);
  factory ValidationResult.failure(List<String> errors) =>
      ValidationResult._(false, errors);

  @override
  String toString() =>
      isValid ? 'ValidationResult(valid)' : 'ValidationResult(errors: $errors)';
}
