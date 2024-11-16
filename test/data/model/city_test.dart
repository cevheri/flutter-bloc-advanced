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
      final finalCity = cityMockPayload;

      expect(finalCity.id, 1);
      expect(finalCity.name, 'istanbul');
      expect(finalCity.plateCode, '34');
    });

    test('should copy a City instance with new values (copyWith)', () {
      final updatedCity = cityMockPayload.copyWith(
        name: 'ankara',
        plateCode: '06',
      );

      expect(updatedCity.id, 1);
      expect(updatedCity.name, 'ankara');
      expect(updatedCity.plateCode, '06');
    });

    test('should compare two City instances', () {
      final updatedCity = cityMockPayload.copyWith(
        id: 1,
        name: 'ankara',
        plateCode: '06',
      );

      expect(cityMockPayload == updatedCity, false);
    });
  });
}
