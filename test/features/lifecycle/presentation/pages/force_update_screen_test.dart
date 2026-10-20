@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/force_update_screen.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/lifecycle_gate.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/url_launcher_stub.dart';

void main() {
  const storeUrl = 'https://play.google.com/store/apps/details?id=com.example.app';
  final updateButton = find.descendant(of: find.byType(ForceUpdateScreen), matching: find.byType(AppButton));

  // App does not mount LifecycleGate yet, so the gate is pumped on its own, with the app theme. The server asks for a
  // version above any real one, so the app must update from the store.
  Future<void> pumpForceUpdateScreen(
    WidgetTester tester, {
    required String? storeUrl,
    Locale locale = const Locale('en'),
  }) async {
    final repository = MockILifecycleRepository();
    when(() => repository.fetchAppConfig())
        .thenAnswer((_) async => Success(AppConfigEntity(minimumVersion: '999.0.0', storeUrl: storeUrl)));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: BlocProvider(
          create: (_) =>
              LifecycleBloc(repository: repository, featureFlagService: FeatureFlagService.instance)
                ..add(const LifecycleCheckEvent()),
          child: const LifecycleGate(child: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ForceUpdateScreen), findsOneWidget);
  }

  S l10nOf(WidgetTester tester) => S.of(tester.element(find.byType(ForceUpdateScreen)));

  group('ForceUpdateScreen - store link that does not open', () {
    for (final failure in UrlLauncherFailure.values) {
      testWidgets('tapping the update button shows a message when ${failure.description}', (tester) async {
        final calls = stubFailingUrlLauncher(failure);
        await pumpForceUpdateScreen(tester, storeUrl: storeUrl);

        await expectTapShowsMessage(tester, updateButton);
        expect(calls.requestedUrls, contains(storeUrl));
      });
    }
  });

  group('ForceUpdateScreen - store link that opens', () {
    for (final canLaunch in [true, false]) {
      testWidgets('tapping the update button opens the store and shows no message when canLaunchUrl answers '
          '$canLaunch', (tester) async {
        final calls = stubOpeningUrlLauncher(canLaunch: canLaunch);
        await pumpForceUpdateScreen(tester, storeUrl: storeUrl);

        await expectTapShowsNoMessage(tester, updateButton);
        expect(calls.launchedUrls, [storeUrl]);
      });
    }
  });

  group('ForceUpdateScreen - store URL that is not https', () {
    for (final rejectedUrl in [
      'http://play.google.com/store/apps/details?id=com.example.app',
      'market://details?id=com.example.app',
      'https:///store/apps/details',
      'https://[::1',
    ]) {
      testWidgets('tapping the update button for $rejectedUrl shows a message and never reaches url_launcher', (
        tester,
      ) async {
        // A device that opens every link, so only the app can refuse this one.
        final calls = stubOpeningUrlLauncher(canLaunch: true);
        await pumpForceUpdateScreen(tester, storeUrl: rejectedUrl);

        final addedTexts = await expectTapShowsMessage(tester, updateButton);
        expect(addedTexts, [l10nOf(tester).force_update_store_link_invalid]);
        expect(calls.requestedUrls, isEmpty);
      });
    }
  });

  group('ForceUpdateScreen - no store URL', () {
    testWidgets('explains how to update instead of showing an update button', (tester) async {
      await pumpForceUpdateScreen(tester, storeUrl: null);

      expect(find.text(l10nOf(tester).force_update_no_store_link), findsOneWidget);
      expect(updateButton, findsNothing);
    });
  });

  group('ForceUpdateScreen - language', () {
    testWidgets('shows its texts in Turkish when the app language is Turkish', (tester) async {
      await pumpForceUpdateScreen(tester, storeUrl: storeUrl, locale: const Locale('tr'));

      // Literal Turkish: a key missing from the Turkish messages falls back to English, which S would also return.
      expect(find.text('Güncelleme Gerekli'), findsOneWidget);
      expect(
        find.text('Yeni bir sürüm mevcut. Uygulamayı kullanmaya devam etmek için lütfen güncelleyin.'),
        findsOneWidget,
      );
      expect(find.text('Mevcut: ${AppConstants.appVersion}  •  Gerekli: 999.0.0'), findsOneWidget);
      expect(find.text('Şimdi Güncelle'), findsOneWidget);
    });
  });
}
