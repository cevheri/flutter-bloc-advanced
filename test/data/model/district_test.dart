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

      expect(finalDistrict.id, '1');
      expect(finalDistrict.name, 'istanbul');
      expect(finalDistrict.code, '01');
    });

    test('should copy a District instance with new values (copyWith)', () {
      final finalDistrict = districtMockPayload;
      final updatedDistrict = finalDistrict.copyWith(
        id: '1',
        name: 'ankara',
        code: '01',
      );

      expect(updatedDistrict.id, '1');
      expect(updatedDistrict.name, 'ankara');
      expect(updatedDistrict.code, '01');
    });

    test('should compare two District instances', () {
      final finalDistrict = districtMockPayload;
      final updatedDistrict = finalDistrict.copyWith(
        id: '1',
        name: 'ankara',
        code: '01',
      );

      ///districtModel and updatedDistrict should not be equal because they have different name values.
      expect(finalDistrict == updatedDistrict, false);
    });
  });
}
