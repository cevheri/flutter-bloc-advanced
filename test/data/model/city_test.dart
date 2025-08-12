import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/city.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/city_data.dart';

/// Test the City model
void main() {
  setUp(() {
    initializeJsonMapper();
  });

  group("City Model", () {
    test('should create a City instance (Constructor)', () {
      const entity = mockCityPayload;

      expect(entity.id, "1");
      expect(entity.name, 'istanbul');
      expect(entity.plateCode, '34');
    });

    test('should copy a City instance with new values (copyWith) new data', () {
      final entityUpd = mockCityPayload.copyWith(name: 'ankara', plateCode: '06');

      expect(entityUpd.id, "1");
      expect(entityUpd.name, 'ankara');
      expect(entityUpd.plateCode, '06');
    });

    test('should copy a City instance with new values (copyWith)', () {
      final entityUpd = mockCityPayload.copyWith();

      expect(entityUpd == mockCityPayload, true);
    });

    test('should compare two City instances', () {
      final entityUpd = mockCityPayload.copyWith(id: "1", name: 'ankara', plateCode: '06');

      expect(mockCityPayload == entityUpd, false);
    });
  });

  //fromJson, fromJsonString, toJson, props
  group("City Model Json Test", () {
    test('should convert City from Json', () {
      final json = mockCityPayload.toJson();
      final entity = City.fromJson(json!);

      expect(entity?.id, "1");
      expect(entity?.name, 'istanbul');
      expect(entity?.plateCode, '34');
    });

    test('should convert City from JsonString', () {
      final jsonString = jsonEncode(mockCityPayload.toJson());
      final entity = City.fromJsonString(jsonString);

      expect(entity?.id, "1");
      expect(entity?.name, 'istanbul');
      expect(entity?.plateCode, '34');
    });

    test('should convert City to Json', () {
      final json = mockCityPayload.toJson()!;

      expect(json['id'], "1");
      expect(json['name'], 'istanbul');
      expect(json['plateCode'], '34');
    });

    test("to string method", () {
      const entity = mockCityPayload;

      expect(entity.toString(), "City(1, istanbul, 34)");
    });
    test("props", () {
      const entity = mockCityPayload;

      expect(entity.props, ["1", "istanbul", "34"]);
    });
  });
}
