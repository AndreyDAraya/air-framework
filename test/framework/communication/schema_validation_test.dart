import 'package:flutter_test/flutter_test.dart';
import 'package:air_framework/framework/communication/schema_validation.dart';

void main() {
  group('StringSchema Tests', () {
    test('Required string fails when null', () {
      const schema = StringSchema(required: true);

      expect(schema.validate(null), isFalse);
      expect(schema.getErrors(null), contains('Value is required'));
    });

    test('Required string fails when empty', () {
      const schema = StringSchema(required: true);

      expect(schema.validate(''), isFalse);
    });

    test('Optional string passes when null', () {
      const schema = StringSchema(required: false);

      expect(schema.validate(null), isTrue);
    });

    test('MinLength validation', () {
      const schema = StringSchema(minLength: 3);

      expect(schema.validate('ab'), isFalse);
      expect(schema.validate('abc'), isTrue);
      expect(schema.validate('abcd'), isTrue);
    });

    test('MaxLength validation', () {
      const schema = StringSchema(maxLength: 5);

      expect(schema.validate('abcdef'), isFalse);
      expect(schema.validate('abcde'), isTrue);
      expect(schema.validate('abc'), isTrue);
    });

    test('Pattern validation', () {
      const schema = StringSchema(pattern: r'^[a-z]+$');

      expect(schema.validate('abc'), isTrue);
      expect(schema.validate('ABC'), isFalse);
      expect(schema.validate('123'), isFalse);
    });

    test('Email pattern validation', () {
      const schema = StringSchema(
        required: true,
        pattern: r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      );

      expect(schema.validate('test@example.com'), isTrue);
      expect(schema.validate('invalid-email'), isFalse);
    });
  });

  group('NumberSchema Tests', () {
    test('Required number fails when null', () {
      const schema = NumberSchema(required: true);

      expect(schema.validate(null), isFalse);
      expect(schema.getErrors(null), contains('Value is required'));
    });

    test('Optional number passes when null', () {
      const schema = NumberSchema(required: false);

      expect(schema.validate(null), isTrue);
    });

    test('Min value validation', () {
      const schema = NumberSchema(min: 0);

      expect(schema.validate(-1), isFalse);
      expect(schema.validate(0), isTrue);
      expect(schema.validate(1), isTrue);
    });

    test('Max value validation', () {
      const schema = NumberSchema(max: 100);

      expect(schema.validate(101), isFalse);
      expect(schema.validate(100), isTrue);
      expect(schema.validate(50), isTrue);
    });

    test('Min and max range validation', () {
      const schema = NumberSchema(min: 0, max: 100);

      expect(schema.validate(-1), isFalse);
      expect(schema.validate(101), isFalse);
      expect(schema.validate(50), isTrue);
    });
  });

  group('BoolSchema Tests', () {
    test('Required bool fails when null', () {
      const schema = BoolSchema(required: true);

      expect(schema.validate(null), isFalse);
    });

    test('Optional bool passes when null', () {
      const schema = BoolSchema(required: false);

      expect(schema.validate(null), isTrue);
    });

    test('Bool values pass validation', () {
      const schema = BoolSchema(required: true);

      expect(schema.validate(true), isTrue);
      expect(schema.validate(false), isTrue);
    });
  });

  group('ListSchema Tests', () {
    test('Required list fails when null', () {
      const schema = ListSchema<String>(required: true);

      expect(schema.validate(null), isFalse);
    });

    test('Optional list passes when null', () {
      const schema = ListSchema<String>(required: false);

      expect(schema.validate(null), isTrue);
    });

    test('MinItems validation', () {
      const schema = ListSchema<String>(minItems: 2);

      expect(schema.validate(['one']), isFalse);
      expect(schema.validate(['one', 'two']), isTrue);
    });

    test('MaxItems validation', () {
      const schema = ListSchema<String>(maxItems: 2);

      expect(schema.validate(['one', 'two', 'three']), isFalse);
      expect(schema.validate(['one', 'two']), isTrue);
    });

    test('List with number type', () {
      const schema = ListSchema<int>(required: true, minItems: 1);

      expect(schema.validate([1, 2, 3]), isTrue);
      expect(schema.validate([]), isFalse);
    });
  });

  group('MapSchema Tests', () {
    test('Required map fails when null', () {
      final schema = MapSchema({}, required: true);

      expect(schema.validate(null), isFalse);
    });

    test('Optional map passes when null', () {
      final schema = MapSchema({}, required: false);

      expect(schema.validate(null), isTrue);
    });

    test('Property validation', () {
      final schema = MapSchema({
        'name': const StringSchema(required: true),
        'age': const NumberSchema(min: 0),
      });

      expect(schema.validate({'name': 'John', 'age': 25}), isTrue);
      expect(schema.validate({'name': null, 'age': 25}), isFalse);
      expect(schema.validate({'name': 'John', 'age': -1}), isFalse);
    });

    test('Additional properties allowed by default', () {
      final schema = MapSchema({'name': const StringSchema(required: true)});

      expect(schema.validate({'name': 'John', 'extra': 'field'}), isTrue);
    });

    test('Additional properties can be disallowed', () {
      final schema = MapSchema({
        'name': const StringSchema(required: true),
      }, additionalProperties: false);

      expect(schema.validate({'name': 'John', 'extra': 'field'}), isFalse);
    });
  });

  group('EventSchemaValidator Tests', () {
    setUp(() {
      EventSchemaValidator().clear();
    });

    test('Validation can be enabled and disabled', () {
      EventSchemaValidator().disable();
      expect(EventSchemaValidator().isEnabled, isFalse);

      EventSchemaValidator().enable();
      expect(EventSchemaValidator().isEnabled, isTrue);
    });

    test('Register signal schema', () {
      final schema = MapSchema({'email': const StringSchema(required: true)});

      EventSchemaValidator().registerSignalSchema('user.login', schema);

      final result = EventSchemaValidator().validateSignal('user.login', {
        'email': 'test@test.com',
      });

      expect(result.isValid, isTrue);
    });

    test('Validate signal with invalid data', () {
      final schema = MapSchema({'email': const StringSchema(required: true)});

      EventSchemaValidator().registerSignalSchema('user.login', schema);

      final result = EventSchemaValidator().validateSignal('user.login', {
        'email': null,
      });

      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('Unregistered signal passes validation', () {
      final result = EventSchemaValidator().validateSignal(
        'unregistered.signal',
        {'any': 'data'},
      );

      expect(result.isValid, isTrue);
    });

    test('Disabled validator passes all validation', () {
      final schema = MapSchema({'email': const StringSchema(required: true)});

      EventSchemaValidator().registerSignalSchema('user.login', schema);
      EventSchemaValidator().disable();

      final result = EventSchemaValidator().validateSignal('user.login', {
        'email': null,
      });

      expect(result.isValid, isTrue);
    });
  });

  group('ValidationResult Tests', () {
    test('Success result', () {
      final result = ValidationResult.success();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Failure result', () {
      final result = ValidationResult.failure(['Error 1', 'Error 2']);

      expect(result.isValid, isFalse);
      expect(result.errors.length, 2);
    });

    test('toString representation', () {
      expect(ValidationResult.success().toString(), 'ValidationResult(valid)');

      expect(
        ValidationResult.failure(['error']).toString(),
        contains('errors'),
      );
    });
  });
}
