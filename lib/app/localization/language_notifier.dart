import 'package:flutter/foundation.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

class LanguageNotifier {
  LanguageNotifier._();

  static final ValueNotifier<String> current = ValueNotifier<String>(AppLocalStorageCached.language ?? 'en');
}
