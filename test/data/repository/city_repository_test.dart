import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/models/city.dart';
import 'package:flutter_bloc_advance/data/repository/city_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/city_data.dart';
import '../../test_utils.dart';

void main() {
  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });
  //endregion setup

  //createCity
  group("CityRepository Create success", () {
    test("Given valid city when create then return city successfully", () async {
      TestUtils().setupAuthentication();
      const entity = mockCityPayload;
      final result = await CityRepository().create(entity);

      expect(result, isA<City>());
      expect(result?.id, "1");
      expect(result?.name, "name");
      expect(result?.plateCode, "plateCode");
    });
    test("Given valid city without AccessToken when create then return city fail", () async {
      const entity = mockCityPayload;
      expect(() async => await CityRepository().create(entity), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null city when create then return city fail", () async {
      expect(() async => await CityRepository().create(const City()), throwsA(isA<BadRequestException>()));
    });
    test("Given null city when create then return city fail", () async {
      expect(() async => await CityRepository().create(const City(name: "")), throwsA(isA<BadRequestException>()));
    });
  });

  //getCities
  group("CityRepository Get success", () {
    test("Given valid when getCities then return cities successfully", () async {
      TestUtils().setupAuthentication();
      final result = await CityRepository().list();

      expect(result, isA<List>());
      expect(result.length, 2);
      expect(result[0]?.id, "1");
      expect(result[0]?.name, "name");
      expect(result[0]?.plateCode, "plateCode");
      expect(result[1]?.id, "2");
      expect(result[1]?.name, "name2");
      expect(result[1]?.plateCode, "plateCode2");
    });
    test("Given valid without AccessToken when getCities then return cities fail", () async {
      expect(() async => await CityRepository().list(), throwsA(isA<UnauthorizedException>()));
    });
  });

  //getCity
  group("CityRepository Get success", () {
    test("Given valid id when getCity then return city successfully", () async {
      TestUtils().setupAuthentication();
      final result = await CityRepository().retrieve("1");

      expect(result, isA<City>());
      expect(result?.id, "1");
      expect(result?.name, "name");
      expect(result?.plateCode, "plateCode");
    });
    test("Given valid id without AccessToken when getCity then return city fail", () async {
      expect(() async => await CityRepository().retrieve("1"), throwsA(isA<UnauthorizedException>()));
    });
    test("Given null id when getCity then return city fail", () async {
      expect(() async => await CityRepository().retrieve(""), throwsA(isA<BadRequestException>()));
    });
  });

  //deleteCity
  group("CityRepository Delete success", () {
    test("Given valid id when deleteCity then return successful", () async {
      TestUtils().setupAuthentication();

      expect(() async => await CityRepository().delete("1"), returnsNormally);
    });
    test("Given valid id without AccessToken when deleteCity then return fail", () async {
      expect(() async => await CityRepository().delete("1"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null id when deleteCity then return fail", () async {
      expect(() async => await CityRepository().delete(""), throwsA(isA<BadRequestException>()));
    });
  });
}
