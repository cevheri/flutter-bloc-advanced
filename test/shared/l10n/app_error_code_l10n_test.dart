@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/shared/l10n/app_error_code_l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden_app.dart';

void main() {
  /// The English sentence [code] resolves to.
  Future<String> resolved(WidgetTester tester, AppErrorCode code) async {
    late BuildContext context;
    await pumpWithLocalizations(
      tester,
      Builder(
        builder: (builderContext) {
          context = builderContext;
          return const SizedBox();
        },
      ),
    );
    await tester.pumpAndSettle();
    return code.resolve(context);
  }

  group('single sign-on error codes', () {
    const sentences = {
      AppErrorCode.authOidcConfig:
          'Single sign-on is not configured correctly in this app. Contact your administrator.',
      AppErrorCode.authOidcDiscovery: 'The identity provider could not be reached. Try again later, or contact your administrator if this continues.',
      AppErrorCode.authOidcNoRole: 'Your account has no role that allows access to this app. Ask your administrator.',
      AppErrorCode.authOidcNoClaims: 'Sign-in failed. Please try again.',
      AppErrorCode.authOidcFailed: 'Sign-in failed. Please try again.',
      AppErrorCode.authOidcLogoutIncomplete:
          'You are signed out of this app, but your session at the identity provider may still be active.',
    };

    for (final MapEntry(key: code, value: sentence) in sentences.entries) {
      testWidgets('${code.name} resolves to its English sentence', (tester) async {
        expect(await resolved(tester, code), sentence);
      });
    }

    testWidgets('authOidcNoClaims shows the same sentence as authOidcFailed', (tester) async {
      expect(
        await resolved(tester, AppErrorCode.authOidcNoClaims),
        await resolved(tester, AppErrorCode.authOidcFailed),
      );
    });
  });
}
