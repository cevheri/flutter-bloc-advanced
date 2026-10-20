@Tags(['widget'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/localization/locale_cubit.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/shared/widgets/language_selection_dialog.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device preferences that finish storing a language only when the test completes [write].
class _HeldWriteStorage implements AppLocalStorage {
  final write = Completer<bool>();
  final storedValues = <Object?>[];

  @override
  Future<bool> save(String key, dynamic value) {
    storedValues.add(value);
    return write.future;
  }

  @override
  Future<dynamic> read(String key) => AppLocalStorage().read(key);
  @override
  Future<bool> remove(String key) => AppLocalStorage().remove(key);
  @override
  Future<void> clear() => AppLocalStorage().clear();
  @override
  void setPreferencesInstance(SharedPreferences prefs) => AppLocalStorage().setPreferencesInstance(prefs);
}

void main() {
  /// Opens the dialog in an app that shows the language of [cubit], as `App` does.
  Future<void> openDialog(WidgetTester tester, LocaleCubit cubit) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, state) => MaterialApp(
            locale: state.locale,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    TextButton(onPressed: () => LanguageSelectionDialog.show(context), child: const Text('open')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// A cubit that shows English, the language stored on the device.
  Future<LocaleCubit> restoredCubit(AppLocalStorage storage) async {
    await AppLocalStorage().save(StorageKeys.language.key, 'en');
    final cubit = LocaleCubit(storage: storage, defaultLocale: const Locale('en'));
    addTearDown(cubit.close);
    await cubit.restore();
    return cubit;
  }

  testWidgets('offers every language the app supports and checks the one it shows', (tester) async {
    await openDialog(tester, await restoredCubit(AppLocalStorage()));

    expect(find.byType(RadioListTile<Locale>), findsNWidgets(S.delegate.supportedLocales.length));
    expect(
      tester.getSemantics(find.widgetWithText(RadioListTile<Locale>, 'English')),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true),
    );
    expect(
      tester.getSemantics(find.widgetWithText(RadioListTile<Locale>, 'Türkçe')),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: false),
    );
  });

  testWidgets('names each language in its own language, whatever language the app shows', (tester) async {
    await AppLocalStorage().save(StorageKeys.language.key, 'tr');
    final cubit = LocaleCubit(storage: AppLocalStorage(), defaultLocale: const Locale('en'));
    addTearDown(cubit.close);
    await cubit.restore();
    await openDialog(tester, cubit);

    expect(find.text('Dil Seçimi'), findsOneWidget, reason: 'the dialog is shown in Turkish');
    expect(find.widgetWithText(RadioListTile<Locale>, 'English'), findsOneWidget);
    expect(find.widgetWithText(RadioListTile<Locale>, 'Türkçe'), findsOneWidget);
  });

  testWidgets('takes no second pick while the first one is being stored', (tester) async {
    final storage = _HeldWriteStorage();
    final cubit = await restoredCubit(storage);
    await openDialog(tester, cubit);

    // A double tap: English stays checked until Turkish is stored, so Turkish can be picked again meanwhile.
    await tester.tap(find.text('Türkçe'));
    await tester.pump();
    await tester.tap(find.text('Türkçe'));
    await tester.pump();

    expect(storage.storedValues, ['tr']);

    storage.write.complete(true);
    await tester.pumpAndSettle();

    expect(cubit.state, const LocaleReady(locale: Locale('tr')));
    expect(find.byType(LanguageSelectionDialog), findsNothing);
  });

  /// Tries to close the dialog as a user can: a tap outside it, then the system back.
  Future<void> tryToDismiss(WidgetTester tester) async {
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 40));
  }

  testWidgets('stays open while a pick is being stored and then closes alone, keeping the page under it', (
    tester,
  ) async {
    final storage = _HeldWriteStorage();
    final cubit = await restoredCubit(storage);
    await openDialog(tester, cubit);
    await tester.tap(find.text('Türkçe'));
    await tester.pump();

    await tryToDismiss(tester);

    expect(find.byType(LanguageSelectionDialog), findsOneWidget);

    storage.write.complete(true);
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectionDialog), findsNothing);
    expect(find.text('open'), findsOneWidget, reason: 'the page under the dialog stays');
    expect(cubit.state, const LocaleReady(locale: Locale('tr')));
  });

  testWidgets('says that a pick could not be stored even after an attempt to dismiss it while it was stored', (
    tester,
  ) async {
    final storage = _HeldWriteStorage();
    final cubit = await restoredCubit(storage);
    await openDialog(tester, cubit);
    await tester.tap(find.text('Türkçe'));
    await tester.pump();

    await tryToDismiss(tester);
    storage.write.complete(false);
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectionDialog), findsNothing);
    expect(find.text('open'), findsOneWidget, reason: 'the page under the dialog stays');
    expect(find.text('Could not change the language'), findsOneWidget);

    // Let the snack bar time out.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
