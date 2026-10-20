@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/app/shell/responsive_scaffold.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

/// The app on the mock-backed development config, with the idle timeout turned on as production has it.
const _app = App(
  language: 'en',
  dependencies: AppDependencies(
    appConfig: AppConfig(
      environment: Environment.dev,
      apiBaseUrl: null,
      certificatePins: <String>[],
      idleTimeout: Duration(minutes: 5),
    ),
  ),
);

void main() {
  group('AppSessionListeners', () {
    testWidgets('an idle timeout clears the stored session, so a relaunch opens the login screen', (tester) async {
      TestEnv.authenticate();
      await FlutterSecureStorageAdapter().write(SecureStorageKeys.refreshToken.key, 'MOCK_REFRESH_TOKEN');
      await AppLocalStorage().save(StorageKeys.roles.key, <String>['ROLE_ADMIN']);
      await tester.pumpWidget(_app);
      await tester.pumpAndSettle();
      expect(find.byType(ResponsiveScaffold), findsOneWidget);

      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);

      // A relaunch mounts a new App, which restores the session from storage.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app);
      await tester.pumpAndSettle();
      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);
      expect(find.byType(ResponsiveScaffold), findsNothing);
      expect(await FlutterSecureStorageAdapter().read(SecureStorageKeys.refreshToken.key), isNull);
      expect(await AppLocalStorage().read(StorageKeys.roles.key), isNull);
    });
  });
}
