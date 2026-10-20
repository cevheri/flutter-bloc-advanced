@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/feature_flags/feature_flag_service.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/usecases/fetch_app_config_usecase.dart';
import 'package:flutter_bloc_advance/features/lifecycle/domain/entities/app_config_entity.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/maintenance_screen.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockILifecycleRepository repository;

  setUp(() {
    repository = MockILifecycleRepository();
    when(() => repository.fetchAppConfig()).thenAnswer((_) async => const Success(AppConfigEntity()));
  });

  Future<void> pumpMaintenanceScreen(
    WidgetTester tester, {
    String? message,
    String? estimatedEnd,
    bool checking = false,
    Locale locale = const Locale('en'),
  }) async {
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
          create: (_) => LifecycleBloc(
            fetchAppConfigUseCase: FetchAppConfigUseCase(repository),
            featureFlagService: FeatureFlagService.instance,
          ),
          child: MaintenanceScreen(message: message, estimatedEnd: estimatedEnd, checking: checking),
        ),
      ),
    );
    // The busy retry button spins until the check ends, so a screen that is checking never settles.
    checking ? await tester.pump() : await tester.pumpAndSettle();
  }

  group('MaintenanceScreen', () {
    testWidgets('shows its texts in English when the app language is English', (tester) async {
      await pumpMaintenanceScreen(tester);

      expect(find.text('Under Maintenance'), findsOneWidget);
      expect(find.text('We are performing scheduled maintenance. Please check back soon.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows its texts in Turkish when the app language is Turkish', (tester) async {
      await pumpMaintenanceScreen(tester, locale: const Locale('tr'));

      // Literal Turkish: a key missing from the Turkish messages falls back to English, which S would also return.
      expect(find.text('Bakım Yapılıyor'), findsOneWidget);
      expect(
        find.text('Planlı bir bakım çalışması yapıyoruz. Lütfen kısa bir süre sonra tekrar deneyin.'),
        findsOneWidget,
      );
      expect(find.text('Tekrar Dene'), findsOneWidget);
    });

    testWidgets('shows the message the app config gives in place of the default one', (tester) async {
      await pumpMaintenanceScreen(tester, message: 'Database upgrade in progress.');

      expect(find.text('Database upgrade in progress.'), findsOneWidget);
      expect(find.text('We are performing scheduled maintenance. Please check back soon.'), findsNothing);
    });

    // A time without an offset is read as local time, so the expected text does not depend on the machine's zone.
    for (final (locale, expected) in [
      (const Locale('en'), 'Estimated end: Wed, Oct 21 2:30 PM'),
      (const Locale('tr'), 'Tahmini bitiş: 21 Eki Çar 14:30'),
    ]) {
      testWidgets('shows when the maintenance is expected to end, in the ${locale.languageCode} format', (
        tester,
      ) async {
        await pumpMaintenanceScreen(tester, estimatedEnd: '2026-10-21T14:30:00', locale: locale);

        expect(find.text(expected), findsOneWidget);
      });
    }

    testWidgets('leaves out an end time that is not a date and time, and logs an error', (tester) async {
      final errors = <String>[];
      void record(OutputEvent event) {
        if (event.level == Level.error) errors.addAll(event.lines);
      }

      Logger.addOutputListener(record);
      addTearDown(() => Logger.removeOutputListener(record));

      await pumpMaintenanceScreen(tester, estimatedEnd: 'after lunch');

      expect(find.textContaining('after lunch'), findsNothing);
      expect(find.textContaining('Estimated end'), findsNothing);
      expect(errors, contains(allOf(contains('MaintenanceScreen : '), contains('after lunch'))));
    });

    testWidgets('logs an end time that is not a date and time once, however often the screen rebuilds', (tester) async {
      final rejected = <String>[];
      void record(OutputEvent event) {
        if (event.level == Level.error && event.lines.any((line) => line.contains('Rejected'))) {
          rejected.add(event.lines.join('\n'));
        }
      }

      Logger.addOutputListener(record);
      addTearDown(() => Logger.removeOutputListener(record));

      await pumpMaintenanceScreen(tester, estimatedEnd: 'after lunch');
      await pumpMaintenanceScreen(tester, estimatedEnd: 'after lunch', checking: true);
      await pumpMaintenanceScreen(tester, estimatedEnd: 'after lunch');

      expect(rejected, hasLength(1));

      await pumpMaintenanceScreen(tester, estimatedEnd: 'before dinner');

      expect(rejected, hasLength(2));
      expect(rejected.last, contains('before dinner'));
    });

    testWidgets('shows the retry button busy while a check runs', (tester) async {
      await pumpMaintenanceScreen(tester, checking: true);

      expect(tester.widget<AppButton>(find.byType(AppButton)).isLoading, isTrue);
    });

    testWidgets('checks the app config again when the user retries', (tester) async {
      await pumpMaintenanceScreen(tester);

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      verify(() => repository.fetchAppConfig()).called(1);
    });
  });
}
