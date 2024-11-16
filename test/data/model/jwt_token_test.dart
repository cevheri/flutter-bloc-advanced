import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

///Test the JWTToken model
void main() {
  setUp(() {
    initializeJsonMapper();
  });

  group("JWTToken model", () {
    test('should create a JWTToken instance (Constructor)', () {
      final finalJWTToken = jWTTokenMockPayload;
      expect(finalJWTToken.idToken, 'idToken');
    });

    test('should copy a JWTToken instance with new values (copyWith)', () {
      final finalJWTToken = jWTTokenMockPayload;
      final updatedJWTToken = finalJWTToken.copyWith(
        idToken: 'new_idToken',
      );
      expect(updatedJWTToken.idToken, 'new_idToken');
    });

    test('should compare two JWTToken  instances', () {
      final finalJWTToken = jWTTokenMockPayload;
      final updatedJWTToken = finalJWTToken.copyWith(
        idToken: 'new_idToken',
      );
      expect(finalJWTToken == updatedJWTToken, false);
    });
  });
}
