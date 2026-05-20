import 'dart:convert';

import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_bundle_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormBundleModel.fromJsonString', () {
    test('parses schema + values from a single response body', () {
      final body = jsonEncode({
        'schema': {
          'id': 'user_extended_info',
          'title': 'Extended Information',
          'fields': [
            {'type': 'text', 'key': 'firstName', 'label': 'First name'},
          ],
          'submitAction': {'method': 'PUT', 'endpoint': '/admin/users/:id/extended'},
        },
        'values': {'firstName': 'Alice', 'newsletter': true},
      });

      final bundle = FormBundleModel.fromJsonString(body);

      expect(bundle.schema.id, 'user_extended_info');
      expect(bundle.schema.title, 'Extended Information');
      expect(bundle.schema.fields, hasLength(1));
      expect(bundle.schema.submitAction?.method, 'PUT');
      expect(bundle.values, {'firstName': 'Alice', 'newsletter': true});
    });

    test('defaults values to an empty map when absent', () {
      final body = jsonEncode({
        'schema': {'id': 'x', 'title': 't'},
      });
      final bundle = FormBundleModel.fromJsonString(body);
      expect(bundle.values, isEmpty);
    });
  });
}
