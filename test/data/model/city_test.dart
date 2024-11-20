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
      final finalCity = mockCityPayload;

      expect(finalCity.id, "1");
      expect(finalCity.name, 'istanbul');
      expect(finalCity.plateCode, '34');
    });

    test('should copy a City instance with new values (copyWith) new data', () {
      final updatedCity = mockCityPayload.copyWith(
        name: 'ankara',
        plateCode: '06',
      );

      expect(updatedCity.id, "1");
      expect(updatedCity.name, 'ankara');
      expect(updatedCity.plateCode, '06');
    });

    test('should copy a City instance with new values (copyWith)', () {
      final updatedCity = mockCityPayload.copyWith();

      expect(updatedCity == mockCityPayload, true);
    });

    test('should compare two City instances', () {
      final updatedCity = mockCityPayload.copyWith(
        id: "1",
        name: 'ankara',
        plateCode: '06',
      );

      expect(mockCityPayload == updatedCity, false);
    });
  });

  //fromJson, fromJsonString, toJson, props
  group("City Model Json Test", () {
    test('should convert City from Json', () {
      final json = mockCityPayload.toJson();

      final city = City.fromJson(json!);

      expect(city?.id, "1");
      expect(city?.name, 'istanbul');
      expect(city?.plateCode, '34');
    });

    test('should convert City from JsonString', () {
      final jsonString = jsonEncode(mockCityPayload.toJson());

      final city = City.fromJsonString(jsonString);

      expect(city?.id, "1");
      expect(city?.name, 'istanbul');
      expect(city?.plateCode, '34');
    });

    test('should convert City to Json', () {
      final json = mockCityPayload.toJson()!;
      expect(json['id'], "1");
      expect(json['name'], 'istanbul');
      expect(json['plateCode'], '34');
    });

    test("to string method", () {
      final city = mockCityPayload;
      expect(city.toString(), "City(1, istanbul, 34)");
    });
    test("props", () {
      final city = mockCityPayload;
      expect(city.props, ["1", "istanbul", "34"]);
    });
  });
}
