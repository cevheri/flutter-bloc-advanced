@Tags(['widget'])
library;

import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end smoke: boots the full app in mock mode (`AppConfig.dev()` —
/// `App`'s default dependencies serve `assets/mock/*.json`) and drives
/// cold-start → login → dashboard. Exercises routing + DI + BLoCs + the mock
/// HTTP layer together.
///
/// Runs headless under the normal `flutter test` (no device/emulator). The
/// global bootstrap (`test/flutter_test_config.dart`) supplies the
/// secure-storage mock + a clean storage reset before each test, so the app
/// starts unauthenticated and lands on login.
void main() {
  testWidgets('cold start → login → dashboard (mock mode)', (tester) async {
    await tester.pumpWidget(const App(language: 'en'));
    await tester.pumpAndSettle();

    // Cold start lands on the login screen (no token after the reset).
    expect(find.byKey(loginTextFieldUsernameKey), findsOneWidget);
    expect(find.byKey(loginButtonSubmitKey), findsOneWidget);

    // Log in — mock auth (POST_authenticate.json → MOCK_TOKEN) accepts any creds.
    await tester.enterText(find.byKey(loginTextFieldUsernameKey), 'admin');
    await tester.enterText(find.byKey(loginTextFieldPasswordKey), 'admin');
    await tester.tap(find.byKey(loginButtonSubmitKey));
    await tester.pumpAndSettle();

    // Router redirects to the authenticated shell.
    expect(find.byType(ResponsiveScaffold), findsOneWidget);
  });
}
