import 'package:flutter_bloc_advance/configuration/local_storage.dart';

class SecurityUtils {
  static bool isCurrentUserAdmin() {
    final roles = AppLocalStorageCached.roles;
    if (roles != null) {
      return roles.contains("ROLE_ADMIN");
    } else {
      return false;
    }
  }
}
