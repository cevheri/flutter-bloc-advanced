import 'package:flutter_bloc_advance/configuration/local_storage.dart';

class SecurityUtils {
  static bool isCurrentUserAdmin() {
    if (AppLocalStorageCached.roles != null) {
      return AppLocalStorageCached.roles!.contains("ROLE_ADMIN");
    } else {
      return false;
    }
  }
}
