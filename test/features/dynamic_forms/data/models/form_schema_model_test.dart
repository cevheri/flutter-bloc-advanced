import 'dart:convert';

import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_schema_model.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Full JSON schema matching the mock data structure.
  final fullJson = <String, dynamic>{
    'id': 'create_lead',
    'title': 'New Lead',
    'description': 'Create a new sales lead entry.',
    'fields': [
      {'type': 'section_header', 'key': '_section_contact', 'label': 'Contact Information'},
      {
        'type': 'text',
        'key': 'name',
        'label': 'Full Name',
        'required': true,
        'validators': ['minLength:2'],
      },
      {'type': 'email', 'key': 'email', 'label': 'Email Address', 'required': true},
      {'type': 'phone', 'key': 'phone', 'label': 'Phone Number', 'hint': '+1 (555) 000-0000'},
      {'type': 'section_header', 'key': '_section_details', 'label': 'Lead Details'},
      {
        'type': 'dropdown',
        'key': 'source',
        'label': 'Lead Source',
        'required': true,
        'options': ['Web', 'Referral', 'Cold Call', 'Conference', 'Social Media'],
      },
      {
        'type': 'radio',
        'key': 'type',
        'label': 'Lead Type',
        'options': ['B2B', 'B2C', 'Partner'],
        'default': 'B2B',
      },
      {'type': 'textarea', 'key': 'notes', 'label': 'Notes', 'maxLines': 4, 'hint': 'Any additional details...'},
      {'type': 'divider', 'key': '_divider_1', 'label': ''},
      {'type': 'date', 'key': 'followUp', 'label': 'Follow-up Date'},
      {'type': 'slider', 'key': 'priority', 'label': 'Priority Level', 'min': 1, 'max': 10, 'default': 5},
      {'type': 'toggle', 'key': 'isHighPriority', 'label': 'High Priority', 'default': false},
      {
        'type': 'multi_select',
        'key': 'tags',
        'label': 'Tags',
        'options': ['Hot', 'Warm', 'Cold', 'VIP', 'Enterprise'],
      },
    ],
    'submitAction': {'method': 'POST', 'endpoint': '/leads'},
    'layout': 'responsive',
  };

  group('FormSchemaModel', () {
    group('fromJson', () {
      test('parses full schema correctly', () {
        final model = FormSchemaModel.fromJson(fullJson);

        expect(model.id, 'create_lead');
        expect(model.title, 'New Lead');
        expect(model.description, 'Create a new sales lead entry.');
        expect(model.fields, hasLength(13));
        expect(model.layout, FormLayout.responsive);
      });

      test('parses minimal schema (id and title only)', () {
        final model = FormSchemaModel.fromJson({'id': 'minimal', 'title': 'Minimal Form'});

        expect(model.id, 'minimal');
        expect(model.title, 'Minimal Form');
        expect(model.description, isNull);
        expect(model.fields, isEmpty);
        expect(model.submitAction, isNull);
        expect(model.layout, FormLayout.responsive);
      });

      test('is a FormSchemaEntity', () {
        final model = FormSchemaModel.fromJson(fullJson);
        expect(model, isA<FormSchemaEntity>());
      });
    });

    group('fromJsonString', () {
      test('parses JSON string correctly', () {
        final jsonString = jsonEncode(fullJson);
        final model = FormSchemaModel.fromJsonString(jsonString);

        expect(model.id, 'create_lead');
        expect(model.title, 'New Lead');
        expect(model.fields, hasLength(13));
      });

      test('parses minimal JSON string', () {
        final jsonString = jsonEncode({'id': 'test', 'title': 'Test'});
        final model = FormSchemaModel.fromJsonString(jsonString);

        expect(model.id, 'test');
        expect(model.title, 'Test');
      });
    });

    group('field type parsing', () {
      FormFieldEntity parseField(Map<String, dynamic> fieldJson) {
        final schema = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [fieldJson],
        });
        return schema.fields.first;
      }

      test('parses text type', () {
        final field = parseField({'type': 'text', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.text);
      });

      test('parses email type', () {
        final field = parseField({'type': 'email', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.email);
      });

      test('parses password type', () {
        final field = parseField({'type': 'password', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.password);
      });

      test('parses number type', () {
        final field = parseField({'type': 'number', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.number);
      });

      test('parses phone type', () {
        final field = parseField({'type': 'phone', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.phone);
      });

      test('parses textarea type', () {
        final field = parseField({'type': 'textarea', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.textarea);
      });

      test('parses dropdown type', () {
        final field = parseField({'type': 'dropdown', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.dropdown);
      });

      test('parses multi_select type (snake_case)', () {
        final field = parseField({'type': 'multi_select', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.multiSelect);
      });

      test('parses multiSelect type (camelCase)', () {
        final field = parseField({'type': 'multiSelect', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.multiSelect);
      });

      test('parses date type', () {
        final field = parseField({'type': 'date', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.date);
      });

      test('parses datetime type', () {
        final field = parseField({'type': 'datetime', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.datetime);
      });

      test('parses toggle type', () {
        final field = parseField({'type': 'toggle', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.toggle);
      });

      test('parses checkbox type', () {
        final field = parseField({'type': 'checkbox', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.checkbox);
      });

      test('parses radio type', () {
        final field = parseField({'type': 'radio', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.radio);
      });

      test('parses slider type', () {
        final field = parseField({'type': 'slider', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.slider);
      });

      test('parses section_header type (snake_case)', () {
        final field = parseField({'type': 'section_header', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.sectionHeader);
      });

      test('parses sectionHeader type (camelCase)', () {
        final field = parseField({'type': 'sectionHeader', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.sectionHeader);
      });

      test('parses divider type', () {
        final field = parseField({'type': 'divider', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.divider);
      });

      test('unknown type defaults to text', () {
        final field = parseField({'type': 'unknown_widget', 'key': 'k', 'label': 'L'});
        expect(field.type, FormFieldType.text);
      });
    });

    group('field properties parsing', () {
      test('parses required field', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'text', 'key': 'name', 'label': 'Name', 'required': true},
          ],
        });

        expect(model.fields.first.required, isTrue);
      });

      test('required defaults to false', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'text', 'key': 'name', 'label': 'Name'},
          ],
        });

        expect(model.fields.first.required, isFalse);
      });

      test('parses readOnly field', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'text', 'key': 'name', 'label': 'Name', 'readOnly': true},
          ],
        });

        expect(model.fields.first.readOnly, isTrue);
      });

      test('parses hint', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'phone', 'key': 'phone', 'label': 'Phone', 'hint': '+1 (555) 000-0000'},
          ],
        });

        expect(model.fields.first.hint, '+1 (555) 000-0000');
      });

      test('parses defaultValue', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'radio', 'key': 'type', 'label': 'Type', 'default': 'B2B'},
          ],
        });

        expect(model.fields.first.defaultValue, 'B2B');
      });

      test('parses options list', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {
              'type': 'dropdown',
              'key': 'source',
              'label': 'Source',
              'options': ['Web', 'Referral', 'Cold Call'],
            },
          ],
        });

        expect(model.fields.first.options, ['Web', 'Referral', 'Cold Call']);
      });

      test('options defaults to empty list when absent', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'text', 'key': 'name', 'label': 'Name'},
          ],
        });

        expect(model.fields.first.options, isEmpty);
      });

      test('parses maxLines', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'textarea', 'key': 'notes', 'label': 'Notes', 'maxLines': 4},
          ],
        });

        expect(model.fields.first.maxLines, 4);
      });

      test('parses min and max as double', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'slider', 'key': 'priority', 'label': 'Priority', 'min': 1, 'max': 10},
          ],
        });

        expect(model.fields.first.min, 1.0);
        expect(model.fields.first.max, 10.0);
      });

      test('min and max default to null', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'text', 'key': 'name', 'label': 'Name'},
          ],
        });

        expect(model.fields.first.min, isNull);
        expect(model.fields.first.max, isNull);
      });
    });

    group('validators parsing', () {
      test('parses validators list', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {
              'type': 'text',
              'key': 'name',
              'label': 'Name',
              'validators': ['minLength:2', 'maxLength:50'],
            },
          ],
        });

        expect(model.fields.first.validators, ['minLength:2', 'maxLength:50']);
      });

      test('validators defaults to empty list when absent', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'fields': [
            {'type': 'text', 'key': 'name', 'label': 'Name'},
          ],
        });

        expect(model.fields.first.validators, isEmpty);
      });
    });

    group('submitAction parsing', () {
      test('parses submitAction with method and endpoint', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'submitAction': {'method': 'POST', 'endpoint': '/leads'},
        });

        expect(model.submitAction, isNotNull);
        expect(model.submitAction!.method, 'POST');
        expect(model.submitAction!.endpoint, '/leads');
      });

      test('submitAction is null when absent', () {
        final model = FormSchemaModel.fromJson({'id': 'test', 'title': 'Test'});

        expect(model.submitAction, isNull);
      });

      test('parses PUT method', () {
        final model = FormSchemaModel.fromJson({
          'id': 'test',
          'title': 'Test',
          'submitAction': {'method': 'PUT', 'endpoint': '/leads/1'},
        });

        expect(model.submitAction!.method, 'PUT');
      });
    });

    group('layout parsing', () {
      test('parses responsive layout', () {
        final model = FormSchemaModel.fromJson({'id': 'test', 'title': 'Test', 'layout': 'responsive'});
        expect(model.layout, FormLayout.responsive);
      });

      test('parses singleColumn layout (camelCase)', () {
        final model = FormSchemaModel.fromJson({'id': 'test', 'title': 'Test', 'layout': 'singleColumn'});
        expect(model.layout, FormLayout.singleColumn);
      });

      test('parses single_column layout (snake_case)', () {
        final model = FormSchemaModel.fromJson({'id': 'test', 'title': 'Test', 'layout': 'single_column'});
        expect(model.layout, FormLayout.singleColumn);
      });

      test('parses twoColumn layout (camelCase)', () {
        final model = FormSchemaModel.fromJson({'id': 'test', 'title': 'Test', 'layout': 'twoColumn'});
        expect(model.layout, FormLayout.twoColumn);
      });

      test('parses two_column layout (snake_case)', () {
        final model = FormSchemaModel.fromJson({'id': 'test', 'title': 'Test', 'layout': 'two_column'});
        expect(model.layout, FormLayout.twoColumn);
      });

      test('defaults to responsive for null layout', () {
        final model = FormSchemaModel.fromJson({'id': 'test', 'title': 'Test'});
        expect(model.layout, FormLayout.responsive);
      });

      test('defaults to responsive for unknown layout value', () {
        final model = FormSchemaModel.fromJson({'id': 'test', 'title': 'Test', 'layout': 'grid'});
        expect(model.layout, FormLayout.responsive);
      });
    });

    group('full mock data', () {
      test('parses the mock JSON file structure correctly', () {
        final model = FormSchemaModel.fromJson(fullJson);

        // Verify all 13 fields
        expect(model.fields, hasLength(13));

        // Verify specific field types from the mock
        expect(model.fields[0].type, FormFieldType.sectionHeader);
        expect(model.fields[1].type, FormFieldType.text);
        expect(model.fields[2].type, FormFieldType.email);
        expect(model.fields[3].type, FormFieldType.phone);
        expect(model.fields[4].type, FormFieldType.sectionHeader);
        expect(model.fields[5].type, FormFieldType.dropdown);
        expect(model.fields[6].type, FormFieldType.radio);
        expect(model.fields[7].type, FormFieldType.textarea);
        expect(model.fields[8].type, FormFieldType.divider);
        expect(model.fields[9].type, FormFieldType.date);
        expect(model.fields[10].type, FormFieldType.slider);
        expect(model.fields[11].type, FormFieldType.toggle);
        expect(model.fields[12].type, FormFieldType.multiSelect);

        // Verify submitAction
        expect(model.submitAction, isNotNull);
        expect(model.submitAction!.method, 'POST');
        expect(model.submitAction!.endpoint, '/leads');

        // Verify a field with validators
        expect(model.fields[1].validators, ['minLength:2']);
        expect(model.fields[1].required, isTrue);

        // Verify a field with options
        expect(model.fields[5].options, hasLength(5));

        // Verify a field with hint
        expect(model.fields[3].hint, '+1 (555) 000-0000');

        // Verify slider min/max
        expect(model.fields[10].min, 1.0);
        expect(model.fields[10].max, 10.0);
      });
    });
  });
}
