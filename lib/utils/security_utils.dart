

import 'package:flutter_bloc_advance/utils/storage.dart';

class SecurityUtils {
  static bool isCurrentUserAdmin() {
    return getStorageCache["role"].contains("ROLE_ADMIN");
  }
}
