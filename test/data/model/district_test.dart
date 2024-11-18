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
      final finalDistrict = districtMockPayload;

      expect(finalDistrict.id, 'id');
      expect(finalDistrict.name, 'kadikoy');
      expect(finalDistrict.code, '34');
    });

    test('should copy a District instance with new values (copyWith)', () {
      final finalDistrict = districtMockPayload;
      final updatedDistrict = finalDistrict.copyWith();

      expect(updatedDistrict.id, 'id');
      expect(updatedDistrict.name, 'kadikoy');
      expect(updatedDistrict.code, '34');
    });

    test('should compare two District instances copyWith ID', () {
      final finalDistrict = districtMockPayload;
      final updatedDistrict = finalDistrict.copyWith(id: '1');

      expect(updatedDistrict.id, '1');
    });

    test('should compare two District instances copyWith name', () {
      final finalDistrict = districtMockPayload;
      final updatedDistrict = finalDistrict.copyWith(name: 'ankara');

      expect(updatedDistrict.name, 'ankara');
    });

    test('should compare two District instances copyWith code', () {
      final finalDistrict = districtMockPayload;
      final updatedDistrict = finalDistrict.copyWith(code: '06');

      expect(updatedDistrict.code, '06');
    });
  });

  // fromJson, fromJsonString, toJson, props
  group("District Model Json Test", () {
    test('should convert District from Json', () {
      final json = districtMockPayload.toJson();

      final district = District.fromJson(json!);

      expect(district?.id, 'id');
      expect(district?.name, 'kadikoy');
      expect(district?.code, '34');
    });

    test('should convert District from Json String', () {
      final jsonString = jsonEncode(districtMockPayload.toJson());

      final district = District.fromJsonString(jsonString);

      expect(district?.id, 'id');
      expect(district?.name, 'kadikoy');
      expect(district?.code, '34');
    });

    test('should convert District to Json', () {
      final district = districtMockPayload;

      final json = district.toJson()!;

      expect(json['id'], 'id');
      expect(json['name'], 'kadikoy');
      expect(json['code'], '34');
    });

    test('should compare two District instances props', () {
      final finalDistrict = districtMockPayload;
      final updatedDistrict = finalDistrict.copyWith();

      expect(finalDistrict.props, updatedDistrict.props);
    });
  });


}
