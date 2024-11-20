import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/district.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/city_data.dart';

void main() {
  setUp(() {
    initializeJsonMapper();
  });

  group("District Model", () {
    test('should create a City instance (Constructor)', () {
      const entity = mockDistrictPayload;

      expect(entity.id, 'id');
      expect(entity.name, 'kadikoy');
      expect(entity.code, '34');
    });

    test('should copy a District instance with new values (copyWith)', () {
      const entity = mockDistrictPayload;
      final entityUpd = entity.copyWith();

      expect(entityUpd.id, 'id');
      expect(entityUpd.name, 'kadikoy');
      expect(entityUpd.code, '34');
    });

    test('should compare two District instances copyWith ID', () {
      const entity = mockDistrictPayload;
      final entityUpd = entity.copyWith(id: '1');

      expect(entityUpd.id, '1');
    });

    test('should compare two District instances copyWith name', () {
      const entity = mockDistrictPayload;
      final entityUpd = entity.copyWith(name: 'ankara');

      expect(entityUpd.name, 'ankara');
    });

    test('should compare two District instances copyWith code', () {
      const entity = mockDistrictPayload;
      final entityUpd = entity.copyWith(code: '06');

      expect(entityUpd.code, '06');
    });
  });

  // fromJson, fromJsonString, toJson, props
  group("District Model Json Test", () {
    test('should convert District from Json', () {
      final json = mockDistrictPayload.toJson();
      final entity = District.fromJson(json!);

      expect(entity?.id, 'id');
      expect(entity?.name, 'kadikoy');
      expect(entity?.code, '34');
    });

    test('should convert District from Json String', () {
      final jsonString = jsonEncode(mockDistrictPayload.toJson());
      final entity = District.fromJsonString(jsonString);

      expect(entity?.id, 'id');
      expect(entity?.name, 'kadikoy');
      expect(entity?.code, '34');
    });

    test('should convert District to Json', () {
      const entity = mockDistrictPayload;
      final json = entity.toJson()!;

      expect(json['id'], 'id');
      expect(json['name'], 'kadikoy');
      expect(json['code'], '34');
    });

    test('should compare two District instances props', () {
      const entity = mockDistrictPayload;
      final entityUpd = entity.copyWith();

      expect(entity.props, entityUpd.props);
    });

    test('toString Properly', () {
      const entity = mockDistrictPayload;

      expect(entity.toString(), 'District(id, kadikoy, 34)');
    });
  });
}
