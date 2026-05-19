/// Typed registry of error codes the application can emit.
///
/// BLoC error states carry these instead of hardcoded English strings,
/// so the UI can translate them via i18n (see the `AppErrorCodeL10n`
/// extension in `lib/shared/l10n/`).
///
/// The [key] is the *domain-facing* stable identifier — for example, it
/// is what use cases attach to `AppError.code` and what gets logged.
/// Renaming an enum value is safe; changing a [key] is a domain-API
/// break that other layers may match on.
///
/// ARB translation keys (in `lib/l10n/intl_*.arb`) are a separate
/// concern, owned by `AppErrorCodeL10n.resolve(BuildContext)` which
/// maps each enum value to the appropriate `S.of(context).error_*`
/// getter. The two namespaces are intentionally distinct because ARB
/// keys must conform to intl_utils' identifier rules.
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
