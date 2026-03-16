import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormSchemaEntity', () {
    test('creates instance with required fields', () {
      const entity = FormSchemaEntity(id: 'form_1', title: 'Test Form');

      expect(entity.id, 'form_1');
      expect(entity.title, 'Test Form');
      expect(entity.description, isNull);
      expect(entity.fields, isEmpty);
      expect(entity.submitAction, isNull);
      expect(entity.layout, FormLayout.responsive);
    });

    test('creates instance with all fields', () {
      const submitAction = FormSubmitAction(method: 'POST', endpoint: '/submit');
      const field = FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Name');
      const entity = FormSchemaEntity(
        id: 'form_1',
        title: 'Test Form',
        description: 'A test form',
        fields: [field],
        submitAction: submitAction,
        layout: FormLayout.twoColumn,
      );

      expect(entity.id, 'form_1');
      expect(entity.title, 'Test Form');
      expect(entity.description, 'A test form');
      expect(entity.fields, hasLength(1));
      expect(entity.submitAction, submitAction);
      expect(entity.layout, FormLayout.twoColumn);
    });

    test('supports value equality (Equatable)', () {
      const entity1 = FormSchemaEntity(id: 'form_1', title: 'Test');
      const entity2 = FormSchemaEntity(id: 'form_1', title: 'Test');
      const entity3 = FormSchemaEntity(id: 'form_2', title: 'Other');

      expect(entity1, equals(entity2));
      expect(entity1, isNot(equals(entity3)));
    });

    test('props contains all relevant fields', () {
      const entity = FormSchemaEntity(id: 'form_1', title: 'Test');

      expect(entity.props, [
        'form_1',
        'Test',
        null, // description
        const <FormFieldEntity>[], // fields
        null, // submitAction
        FormLayout.responsive, // layout
      ]);
    });
  });

  group('FormFieldEntity', () {
    test('creates instance with required fields and defaults', () {
      const field = FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Name');

      expect(field.type, FormFieldType.text);
      expect(field.key, 'name');
      expect(field.label, 'Name');
      expect(field.hint, isNull);
      expect(field.required, isFalse);
      expect(field.readOnly, isFalse);
      expect(field.defaultValue, isNull);
      expect(field.options, isEmpty);
      expect(field.validators, isEmpty);
      expect(field.maxLines, isNull);
      expect(field.min, isNull);
      expect(field.max, isNull);
    });

    test('creates instance with all fields', () {
      const field = FormFieldEntity(
        type: FormFieldType.slider,
        key: 'priority',
        label: 'Priority',
        hint: 'Select priority',
        required: true,
        readOnly: false,
        defaultValue: 5,
        options: ['low', 'medium', 'high'],
        validators: ['minLength:1'],
        maxLines: 3,
        min: 1.0,
        max: 10.0,
      );

      expect(field.type, FormFieldType.slider);
      expect(field.key, 'priority');
      expect(field.label, 'Priority');
      expect(field.hint, 'Select priority');
      expect(field.required, isTrue);
      expect(field.readOnly, isFalse);
      expect(field.defaultValue, 5);
      expect(field.options, ['low', 'medium', 'high']);
      expect(field.validators, ['minLength:1']);
      expect(field.maxLines, 3);
      expect(field.min, 1.0);
      expect(field.max, 10.0);
    });

    test('supports value equality (Equatable)', () {
      const field1 = FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Name');
      const field2 = FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Name');
      const field3 = FormFieldEntity(type: FormFieldType.email, key: 'email', label: 'Email');

      expect(field1, equals(field2));
      expect(field1, isNot(equals(field3)));
    });

    test('props contains expected values', () {
      const field = FormFieldEntity(
        type: FormFieldType.text,
        key: 'name',
        label: 'Name',
        required: true,
        validators: ['minLength:2'],
      );

      expect(field.props, [
        FormFieldType.text,
        'name',
        'Name',
        null, // hint
        true, // required
        false, // readOnly
        null, // defaultValue
        const <String>[], // options (default)
        const ['minLength:2'], // validators
      ]);
    });
  });

  group('FormSubmitAction', () {
    test('creates instance with required fields', () {
      const action = FormSubmitAction(method: 'POST', endpoint: '/api/leads');

      expect(action.method, 'POST');
      expect(action.endpoint, '/api/leads');
    });

    test('supports value equality (Equatable)', () {
      const action1 = FormSubmitAction(method: 'POST', endpoint: '/submit');
      const action2 = FormSubmitAction(method: 'POST', endpoint: '/submit');
      const action3 = FormSubmitAction(method: 'PUT', endpoint: '/update');

      expect(action1, equals(action2));
      expect(action1, isNot(equals(action3)));
    });

    test('props contains method and endpoint', () {
      const action = FormSubmitAction(method: 'POST', endpoint: '/submit');
      expect(action.props, ['POST', '/submit']);
    });
  });

  group('FormFieldType', () {
    test('has all expected enum values', () {
      expect(
        FormFieldType.values,
        containsAll([
          FormFieldType.text,
          FormFieldType.email,
          FormFieldType.password,
          FormFieldType.number,
          FormFieldType.phone,
          FormFieldType.textarea,
          FormFieldType.dropdown,
          FormFieldType.multiSelect,
          FormFieldType.date,
          FormFieldType.datetime,
          FormFieldType.toggle,
          FormFieldType.checkbox,
          FormFieldType.radio,
          FormFieldType.slider,
          FormFieldType.sectionHeader,
          FormFieldType.divider,
        ]),
      );
    });

    test('has exactly 16 values', () {
      expect(FormFieldType.values, hasLength(16));
    });
  });

  group('FormLayout', () {
    test('has all expected enum values', () {
      expect(FormLayout.values, containsAll([FormLayout.responsive, FormLayout.singleColumn, FormLayout.twoColumn]));
    });

    test('has exactly 3 values', () {
      expect(FormLayout.values, hasLength(3));
    });
  });
}
