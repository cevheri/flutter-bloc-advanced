import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/test_env.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => AppLogger.configure(isProduction: false, logFormat: LogFormat.simple));

  setUp(() => TestEnv.reset());

  testWidgets('cold start lands on the login screen (mock mode)', (tester) async {
    await tester.pumpWidget(const App(language: 'en'));
    await tester.pumpAndSettle();

    expect(find.byKey(loginTextFieldUsernameKey), findsOneWidget);
    expect(find.byKey(loginButtonSubmitKey), findsOneWidget);
  });
}
