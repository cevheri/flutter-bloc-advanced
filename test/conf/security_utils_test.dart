import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc_advance/utils/security_utils.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';

import '../test_utils.dart';

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  group('SecurityUtils Tests', () {
    test('isUserLoggedIn should return false when token is null', () {
      expect(SecurityUtils.isUserLoggedIn(), false);
    });

    test('isUserLoggedIn should return true when token exists', () async {
      await TestUtils().setupAuthentication();
      expect(SecurityUtils.isUserLoggedIn(), true);
    });

    test('isCurrentUserAdmin should return false when roles is null', () {
      expect(SecurityUtils.isCurrentUserAdmin(), false);
    });

    test('isCurrentUserAdmin should return true when user has admin role', () async {
      await AppLocalStorage().save(StorageKeys.roles.name, ["ROLE_ADMIN"]);
      expect(SecurityUtils.isCurrentUserAdmin(), true);
    });

    test('isCurrentUserAdmin should return false when user does not have admin role', () async {
      await AppLocalStorage().save(StorageKeys.roles.name, ["ROLE_USER"]);
      expect(SecurityUtils.isCurrentUserAdmin(), false);
    });

    group('isTokenExpired Tests', () {
      test('should return true when token is null', () {
        // expect(SecurityUtils.isTokenExpired(), true); //TODO activate after your custom jtw token expire method implementation
        expect(SecurityUtils.isTokenExpired(), false);
      });

      test('should return true when token is invalid format', () async {
        await AppLocalStorage().save(StorageKeys.jwtToken.name, "invalid.token");
        // expect(SecurityUtils.isTokenExpired(), true); //TODO activate after your custom jtw token expire method implementation
        expect(SecurityUtils.isTokenExpired(), false);
      });

      test('should return true when token payload is invalid', () async {
        await AppLocalStorage().save(StorageKeys.jwtToken.name, "header.invalid_payload.signature");
        //expect(SecurityUtils.isTokenExpired(), true); //TODO activate after your custom jtw token expire method implementation
        expect(SecurityUtils.isTokenExpired(), false);
      });

      test('should return true when exp is missing in payload', () async {
        final payload = base64Url.encode('{"sub":"test"}'.codeUnits);
        await AppLocalStorage().save(StorageKeys.jwtToken.name, "header.$payload.signature");
        //expect(SecurityUtils.isTokenExpired(), true) ; //TODO activate after your custom jtw token expire method implementation
        expect(SecurityUtils.isTokenExpired(), false);
      });

      test('should return true when token is expired', () async {
        final expiredTime = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        final payload = base64Url.encode('{"exp":$expiredTime}'.codeUnits);
        await AppLocalStorage().save(StorageKeys.jwtToken.name, "header.$payload.signature");
        //expect(SecurityUtils.isTokenExpired(), true); //TODO activate after your custom jtw token expire method implementation
        expect(SecurityUtils.isTokenExpired(), false);
      });

      test('should return false when token is valid and not expired', () async {
        final futureTime = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        final payload = base64Url.encode('{"exp":$futureTime}'.codeUnits);
        await AppLocalStorage().save(StorageKeys.jwtToken.name, "header.$payload.signature");
        expect(SecurityUtils.isTokenExpired(), false);
      });
    });
  });
}
