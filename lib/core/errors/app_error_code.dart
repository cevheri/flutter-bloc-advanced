/// Typed registry of error codes the application can emit.
///
/// BLoC error states carry these instead of hardcoded English strings,
/// so the UI can translate them via i18n (see `S.of(context)` and the
/// `AppErrorCodeL10n` extension in `lib/shared/l10n/`).
///
/// The [key] is the stable identifier used in ARB files. Renaming an
/// enum value is safe; changing the [key] is a translation-breaking
/// change.
enum AppErrorCode {
  // --- auth ---
  authInvalidAccessToken('auth.invalid_access_token'),
  authLoginFailed('auth.login_failed'),
  authSendOtpFailed('auth.send_otp_failed'),
  authOtpValidationError('auth.otp_validation_error'),
  authSessionPersistFailed('auth.session_persist_failed'),

  // --- users ---
  userCannotDeleteAdmin('user.cannot_delete_admin'),
  userNoAuthorities('user.no_authorities'),

  // --- account ---
  accountPasswordRequired('account.password_required'),
  accountPasswordsSame('account.passwords_same'),

  // --- settings ---
  settingsChangeLanguageFailed('settings.change_language_failed'),

  // --- generic fallback ---
  generic('error.generic');

  const AppErrorCode(this.key);

  final String key;

  /// Look up a code by its [key]. Returns null when no enum value
  /// matches — callers should fall back to [AppErrorCode.generic] or
  /// surface the raw message.
  static AppErrorCode? fromKey(String? key) {
    if (key == null) return null;
    for (final code in values) {
      if (code.key == key) return code;
    }
    return null;
  }
}
