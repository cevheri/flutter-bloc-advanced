import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormBundleEntity', () {
    const schema = FormSchemaEntity(id: 'x', title: 't');

    test('equality holds when schema and values match', () {
      final a = FormBundleEntity(schema: schema, values: const {'k': 1});
      final b = FormBundleEntity(schema: schema, values: const {'k': 1});
      expect(a, equals(b));
    });

    test('inequality when values differ', () {
      final a = FormBundleEntity(schema: schema, values: const {'k': 1});
      final b = FormBundleEntity(schema: schema, values: const {'k': 2});
      expect(a, isNot(equals(b)));
    });

    test('defaults values to empty map', () {
      const bundle = FormBundleEntity(schema: schema);
      expect(bundle.values, isEmpty);
    });
  });
}
