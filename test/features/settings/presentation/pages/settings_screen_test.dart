@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/features/settings/presentation/pages/settings_screen.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_nav_item.dart';
import 'package:flutter_bloc_advance/infrastructure/config/project_links.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/main/app.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/test_env.dart';
import '../../../../support/url_launcher_stub.dart';

const _docs = 'https://docs.acme.example';

/// Device preferences that refuse to store a language, like a device that is out of space.
class _LanguageRefusingStorage implements AppLocalStorage {
  const _LanguageRefusingStorage();

  @override
  Future<bool> save(String key, dynamic value) async =>
      key == StorageKeys.language.key ? false : AppLocalStorage().save(key, value);
  @override
  Future<dynamic> read(String key) => AppLocalStorage().read(key);
  @override
  Future<bool> remove(String key) => AppLocalStorage().remove(key);
  @override
  Future<void> clear() => AppLocalStorage().clear();
  @override
  void setPreferencesInstance(SharedPreferences prefs) => AppLocalStorage().setPreferencesInstance(prefs);
}

class _LocalStorageDependencies extends AppDependencies {
  const _LocalStorageDependencies(this.localStorage, {super.projectLinks});

  final AppLocalStorage localStorage;

  @override
  AppLocalStorage createLocalStorage() => localStorage;
}

void main() {
  // The build gives the documentation website [docs].
  Widget buildTestableWidget({String docs = _docs}) {
    final router = GoRouter(
      initialLocation: ApplicationRoutesConstants.settings,
      routes: [
        GoRoute(
          path: ApplicationRoutesConstants.settings,
          builder: (context, state) => const Scaffold(body: SettingsScreen()),
        ),
        GoRoute(
          path: ApplicationRoutesConstants.changePassword,
          builder: (context, state) => const Scaffold(body: Placeholder()),
        ),
      ],
    );

    return RepositoryProvider<ProjectLinks>.value(
      value: ProjectLinks(docs: docs),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    );
  }

  // The real app, signed in, on settings. The shell shows the account name in the top bar once the mock API answers
  // after its 500 ms delay, so let that land before the screen is compared. The build gives the documentation website
  // [docs] and, when given, the device preferences [localStorage].
  Future<void> pumpAppOnSettings(WidgetTester tester, {String docs = _docs, AppLocalStorage? localStorage}) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    TestEnv.authenticate();

    final projectLinks = ProjectLinks(docs: docs);
    await tester.pumpWidget(
      App(
        language: 'en',
        dependencies: localStorage == null
            ? AppDependencies(projectLinks: projectLinks)
            : _LocalStorageDependencies(localStorage, projectLinks: projectLinks),
      ),
    );
    await tester.pump();
    (tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig! as GoRouter).go(
      ApplicationRoutesConstants.settings,
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  group('SettingsScreen Tests', () {
    testWidgets('renders all settings tiles', (WidgetTester tester) async {
      TestEnv.authenticate();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Assert via Keys only — text-based asserts would couple the
      // test to the active locale (some titles use S.of(context) /
      // generated strings, others are still literals pending i18n).
      // Key presence is enough to guard the screen layout against
      // accidental tile removal.
      expect(find.byKey(settingsChangePasswordButtonKey), findsOneWidget);
      expect(find.byKey(settingsChangeLanguageButtonKey), findsOneWidget);
      expect(find.byKey(settingsWebsiteButtonKey), findsOneWidget);
      // Logout intentionally lives only in the sidebar / topbar shell —
      // settings does not own auth-session lifecycle (cross-feature).
    });

    // A made-up key: replacing the template's real placeholders across a project leaves this test as it is.
    testWidgets('shows no Help & Resources section while the docs URL is a placeholder', (WidgetTester tester) async {
      TestEnv.authenticate();
      await tester.pumpWidget(buildTestableWidget(docs: '__DOCS__'));
      await tester.pumpAndSettle();

      expect(find.byKey(settingsChangePasswordButtonKey), findsOneWidget);
      expect(find.byKey(settingsWebsiteButtonKey), findsNothing);
      expect(find.text('Help & Resources'), findsNothing);
    });

    testWidgets('navigates to change password screen when button is pressed', (WidgetTester tester) async {
      TestEnv.authenticate();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(settingsChangePasswordButtonKey));
      await tester.pumpAndSettle();

      // Assert we navigated TO the change-password route (its content renders),
      // not merely that the settings screen disappeared.
      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
    });
  });

  group('SettingsScreen - website link that does not open', () {
    for (final failure in UrlLauncherFailure.values) {
      testWidgets('tapping Website shows a message when ${failure.description}', (WidgetTester tester) async {
        final calls = stubFailingUrlLauncher(failure);
        await pumpAppOnSettings(tester);

        await expectTapShowsMessage(tester, find.byKey(settingsWebsiteButtonKey));
        expect(calls.requestedUrls, contains(_docs));
      });
    }
  });

  group('SettingsScreen - language', () {
    testWidgets('choosing Turkish shows the app in Turkish at once and again at the next start', (tester) async {
      await pumpAppOnSettings(tester);
      expect(find.text('Help & Resources'), findsOneWidget);

      await tester.tap(find.byKey(settingsChangeLanguageButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Türkçe'));
      await tester.pumpAndSettle();

      expect(find.text('Yardım ve Kaynaklar'), findsOneWidget);
      expect(find.text('Çıkış Yap'), findsOneWidget, reason: 'the sidebar switches too');
      expect(find.descendant(of: find.byKey(settingsChangeLanguageButtonKey), matching: find.text('Türkçe')), findsOne);
      expect(find.text('Help & Resources'), findsNothing);

      // The next cold start: a new App, which reads the stored language.
      await tester.pumpWidget(const SizedBox());
      await pumpAppOnSettings(tester);

      expect(find.text('Yardım ve Kaynaklar'), findsOneWidget);
      expect(find.text('Help & Resources'), findsNothing);
    });

    testWidgets('keeps the picked language after a logout and at the next start', (tester) async {
      await pumpAppOnSettings(tester);
      await tester.tap(find.byKey(settingsChangeLanguageButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Türkçe'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(SidebarNavItem, Icons.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Evet'));
      await tester.pumpAndSettle();
      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);
      expect(find.text('Şifremi unuttum'), findsOneWidget);

      // The next cold start: a new App, which reads the stored language.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const App(language: 'en'));
      await tester.pumpAndSettle();

      expect(find.byKey(loginButtonSubmitKey), findsOneWidget);
      expect(find.text('Şifremi unuttum'), findsOneWidget);
      expect(find.text('Forgot Password'), findsNothing);
    });

    testWidgets('keeps the language and says so when the device cannot store it', (tester) async {
      await pumpAppOnSettings(tester, localStorage: const _LanguageRefusingStorage());

      await tester.tap(find.byKey(settingsChangeLanguageButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Türkçe'));
      await tester.pumpAndSettle();

      expect(find.text('Could not change the language'), findsOneWidget);
      expect(find.text('Select Language'), findsNothing, reason: 'the dialog closes');
      expect(find.text('Help & Resources'), findsOneWidget);
      expect(find.text('Yardım ve Kaynaklar'), findsNothing);
      expect(await AppLocalStorage().read(StorageKeys.language.key), isNull);

      // Let the snack bar time out.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });
  });

  group('SettingsScreen - website link that opens', () {
    for (final canLaunch in [true, false]) {
      testWidgets('tapping Website opens it and shows no message when canLaunchUrl answers $canLaunch', (
        WidgetTester tester,
      ) async {
        final calls = stubOpeningUrlLauncher(canLaunch: canLaunch);
        await pumpAppOnSettings(tester);

        await expectTapShowsNoMessage(tester, find.byKey(settingsWebsiteButtonKey));
        expect(calls.launchedUrls, [_docs]);
      });
    }
  });
}
