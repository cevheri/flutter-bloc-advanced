import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';

/// Names a language the app supports.
///
/// Lives in `shared/l10n/` next to `AppErrorCodeL10n` because it depends on the generated `S` localization class.
extension LocaleL10n on Locale {
  /// The name of the language in the language the app shows.
  String displayName(BuildContext context) {
    final s = S.of(context);
    return switch (languageCode) {
      'en' => s.english,
      'tr' => s.turkish,
      _ => throw UnsupportedError('No name for the language "$languageCode"; add it to LocaleL10n.displayName'),
    };
  }

  /// The name of the language in the language itself, so a user finds their own language whatever the app shows.
  String get endonym => switch (languageCode) {
    'en' => 'English',
    'tr' => 'Türkçe',
    _ => throw UnsupportedError('No name for the language "$languageCode"; add it to LocaleL10n.endonym'),
  };
}
