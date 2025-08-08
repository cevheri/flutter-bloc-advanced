//import 'dart:convert';

import 'package:flutter_bloc_advance/configuration/allowed_paths.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';

class SecurityUtils {
  static final _log = AppLogger.getLogger("SecurityUtils");

  static bool isUserLoggedIn() {
    _log.trace("BEGIN:isUserLoggedIn");
    final result = AppLocalStorageCached.jwtToken != null;
    _log.trace("END:isUserLoggedIn", [result]);
    return result;
  }

  static bool isCurrentUserAdmin() {
    _log.trace("BEGIN:isCurrentUserAdmin");
    final roles = AppLocalStorageCached.roles;
    if (roles != null) {
      var result = roles.contains("ROLE_ADMIN");
      _log.trace("END:isCurrentUserAdmin - {}", [result]);
      return result;
    } else {
      _log.trace("END:isCurrentUserAdmin - roles null");
      return false;
    }
  }

  static bool isTokenExpired() {
    _log.trace("BEGIN:isTokenExpired");

    //TODO activate your token expiration check
    return false;
    /*
    final token = AppLocalStorageCached.jwtToken;
    if (token != null) {
      try {
        final jwt = token.split(".");
        if (jwt.length == 3) {
          final payload = jwt[1];

          var normalizedPayload = payload;
          if (payload.length % 4 != 0) {
            final padLength = 4 - payload.length % 4;
            normalizedPayload += '=' * padLength;
          }
          final base64Decode = base64Url.decode(normalizedPayload);
          final decoded = String.fromCharCodes(base64Decode);
          final payloadMap = json.decode(decoded);

          if (payloadMap == null) throw Exception("Invalid payload(null)");
          if (payloadMap["exp"] == null) throw Exception("Invalid payload exp(null)");

          final exp = payloadMap["exp"];
          _log.trace("exp: {}", [exp]);
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          _log.trace("now: {}", [now]);

          var result = now >= exp;
          _log.trace("END:isTokenExpired - {}", [result]);
          return result;
        }
      } catch (e) {
        _log.error("END:isTokenExpired - Error parsing token", [e]);
        return true;
      }
    }
    _log.trace("END:isTokenExpired - token null");
    return true;

 */
  }

  /// Check if the path is allowed
  ///
  /// Some paths are allowed to be accessed without JWT token like login, register, forgot-password, etc.
  static bool isAllowedPath(String path) {
    _log.trace("BEGIN:isAllowedPath", [path]);
    final result = allowedPaths.contains(path);
    _log.trace("END:isAllowedPath", [result]);
    return result;
  }
}
