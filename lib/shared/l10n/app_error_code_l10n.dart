import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';

/// Translates an [AppErrorCode] into a localized, user-facing message.
///
/// Lives in `shared/l10n/` (not `core/`) because it depends on the
/// generated `S` localization class. `core/errors/` must stay free of
/// Flutter/i18n dependencies.
extension AppErrorCodeL10n on AppErrorCode {
  String resolve(BuildContext context) {
    final s = S.of(context);
    return switch (this) {
      AppErrorCode.authInvalidAccessToken => s.error_auth_invalid_access_token,
      AppErrorCode.authLoginFailed => s.error_auth_login_failed,
      AppErrorCode.authSendOtpFailed => s.error_auth_send_otp_failed,
      AppErrorCode.authOtpValidationError => s.error_auth_otp_validation,
      AppErrorCode.authSessionPersistFailed => s.error_auth_session_persist_failed,
      AppErrorCode.userCannotDeleteAdmin => s.error_user_cannot_delete_admin,
      AppErrorCode.userNoAuthorities => s.error_user_no_authorities,
      AppErrorCode.accountPasswordRequired => s.error_account_password_required,
      AppErrorCode.accountPasswordsSame => s.error_account_passwords_same,
      AppErrorCode.settingsChangeLanguageFailed => s.error_settings_change_language_failed,
      AppErrorCode.networkCertInvalid => s.error_network_cert_invalid,
      AppErrorCode.generic => s.error_generic,
    };
  }
}
