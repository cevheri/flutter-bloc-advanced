import 'dart:convert';

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/security/allowed_paths.dart';

/// Pure token / role utility functions.
///
/// Intentionally has no I/O dependencies: callers (e.g. [SessionCubit])
/// own the secure-storage read and hand the token here as a String. This
/// keeps `core/` free of `infrastructure/` imports per the architecture
/// guard, and makes every function trivially testable.
class SecurityUtils {
  static final _log = AppLogger.getLogger("SecurityUtils");

  /// True when [token] is non-null and non-empty.
  static bool hasToken(String? token) {
    return token != null && token.isNotEmpty;
  }

  static bool isCurrentUserAdmin(List<String>? roles) {
    if (roles == null) return false;
    return roles.contains("ROLE_ADMIN");
  }

  /// True when [token] is missing, malformed, or past its `exp` claim.
  static bool isTokenExpired(String? token) {
    if (token == null || token.isEmpty) return true;
    try {
      final jwt = token.split(".");
      if (jwt.length != 3) return true;
      var normalizedPayload = jwt[1];
      if (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=' * (4 - normalizedPayload.length % 4);
      }
      final decoded = String.fromCharCodes(base64Url.decode(normalizedPayload));
      final payloadMap = json.decode(decoded);
      if (payloadMap == null) return true;
      final exp = payloadMap["exp"];
      if (exp is! num) return true;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= exp.toInt();
    } catch (e) {
      _log.error("isTokenExpired - error parsing token: {}", [e]);
      return true;
    }
  }

  /// Decode a JWT token and return the expiration time as [DateTime].
  ///
  /// Returns null if the token is invalid or does not contain an `exp` claim.
  static DateTime? getTokenExpiration(String token) {
    _log.trace("BEGIN:getTokenExpiration");
    try {
      final parts = token.split(".");
      if (parts.length != 3) return null;

      var payload = parts[1];
      if (payload.length % 4 != 0) {
        payload += '=' * (4 - payload.length % 4);
      }
      final decoded = String.fromCharCodes(base64Url.decode(payload));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      final exp = payloadMap["exp"];
      if (exp == null) return null;

      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    } catch (e) {
      _log.error("END:getTokenExpiration - Error: {}", [e]);
      return null;
    }
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
