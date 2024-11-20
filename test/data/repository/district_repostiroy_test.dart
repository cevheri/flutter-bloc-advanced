import 'package:flutter_bloc_advance/data/app_api_exception.dart';
import 'package:flutter_bloc_advance/data/models/district.dart';
import 'package:flutter_bloc_advance/data/repository/district_repository.dart';
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

  //getDistrictsByCity
  group("District Repository getDistrictsByCity", () {
    test("Given valid cityId when getDistrictsByCity then return districts successfully", () async {
      TestUtils().setupAuthentication();
      final result = await DistrictRepository().getDistrictsByCity("1");

      expect(result, isA<List>());
      expect(result.length, 2);
      expect(result[0]?.id, "1");
      expect(result[0]?.name, "name");
      expect(result[0]?.code, "code");
      expect(result[1]?.id, "2");
      expect(result[1]?.name, "name2");
      expect(result[1]?.code, "code2");
    });
    test("Given valid cityId without AccessToken when getDistrictsByCity then return districts fail", () async {
      expect(() async => await DistrictRepository().getDistrictsByCity("1"), throwsA(isA<UnauthorizedException>()));
    });
    test("Given null cityId when getDistrictsByCity then return districts fail", () async {
      TestUtils().setupAuthentication();
      expect(() async => await DistrictRepository().getDistrictsByCity(""), throwsA(isA<BadRequestException>()));
    });
  });

  //createDistrict
  group("DistrictRepository Create success", () {
    test("Given valid district when create then return district successfully", () async {
      TestUtils().setupAuthentication();
      const entity = mockDistrictPayload;
      final result = await DistrictRepository().createDistrict(entity);

      expect(result, isA<District>());
      expect(result?.id, "1");
      expect(result?.name, "name");
      expect(result?.code, "code");
    });
    test("Given valid district without AccessToken when create then return district fail", () async {
      const entity = mockDistrictPayload;
      expect(() async => await DistrictRepository().createDistrict(entity), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null district when create then return district fail", () async {
      expect(() async => await DistrictRepository().createDistrict(const District()), throwsA(isA<BadRequestException>()));
    });
    test("Given null district when create then return district fail", () async {
      expect(() async => await DistrictRepository().createDistrict(const District(name: "")), throwsA(isA<BadRequestException>()));
    });
  });

  //getDistricts
  group("DistrictRepository Get success", () {
    test("Given valid when getDistricts then return cities successfully", () async {
      TestUtils().setupAuthentication();
      final result = await DistrictRepository().getDistricts();

      expect(result, isA<List>());
      expect(result.length, 2);
      expect(result[0]?.id, "1");
      expect(result[0]?.name, "name");
      expect(result[0]?.code, "code");
      expect(result[1]?.id, "2");
      expect(result[1]?.name, "name2");
      expect(result[1]?.code, "code2");
    });
    test("Given valid without AccessToken when getDistricts then return cities fail", () async {
      expect(() async => await DistrictRepository().getDistricts(), throwsA(isA<UnauthorizedException>()));
    });
  });

  //getDistrict
  group("DistrictRepository Get success", () {
    test("Given valid id when getDistrict then return district successfully", () async {
      TestUtils().setupAuthentication();
      final result = await DistrictRepository().getDistrict("1");

      expect(result, isA<District>());
      expect(result?.id, "1");
      expect(result?.name, "name");
      expect(result?.code, "code");
    });
    test("Given valid id without AccessToken when getDistrict then return district fail", () async {
      expect(() async => await DistrictRepository().getDistrict("1"), throwsA(isA<UnauthorizedException>()));
    });
    test("Given null id when getDistrict then return district fail", () async {
      expect(() async => await DistrictRepository().getDistrict(""), throwsA(isA<BadRequestException>()));
    });
  });

  //deleteDistrict
  group("DistrictRepository Delete success", () {
    test("Given valid id when deleteDistrict then return successful", () async {
      TestUtils().setupAuthentication();

      expect(() async => await DistrictRepository().deleteDistrict("1"), returnsNormally);
    });
    test("Given valid id without AccessToken when deleteDistrict then return fail", () async {
      expect(() async => await DistrictRepository().deleteDistrict("1"), throwsA(isA<UnauthorizedException>()));
    });

    test("Given null id when deleteDistrict then return fail", () async {
      expect(() async => await DistrictRepository().deleteDistrict(""), throwsA(isA<BadRequestException>()));
    });
  });
}
