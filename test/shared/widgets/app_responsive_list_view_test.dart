@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_skeleton.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_data_table.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_responsive_list_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpList(
    WidgetTester tester, {
    required List<String>? items,
    required bool isLoading,
    Size size = const Size(1200, 800),
    Locale locale = const Locale('en'),
    VoidCallback? onCreateNew,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: AppResponsiveListView<String>(
            title: 'Users',
            items: items,
            isLoading: isLoading,
            onCreateNew: onCreateNew,
            columns: [AppTableColumn<String>(label: 'Name', flex: 1, builder: (_, item) => Text(item))],
            mobileCardBuilder: (_, item) => Text(item),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows placeholder rows instead of an empty table while loading on a desktop', (tester) async {
    await pumpList(tester, items: null, isLoading: true);

    expect(find.byType(AppSkeleton), findsWidgets);
    expect(find.byType(AppDataTable<String>), findsNothing);
    expect(find.text('0 rows listed.'), findsNothing);
  });

  testWidgets('shows the table once loaded on a desktop', (tester) async {
    await pumpList(tester, items: const ['Grace Hopper'], isLoading: false);

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('1 row listed.'), findsOneWidget);
    expect(find.byType(AppSkeleton), findsNothing);
  });

  testWidgets('counts several rows in the plural', (tester) async {
    await pumpList(tester, items: const ['Ada', 'Grace', 'Linus'], isLoading: false);

    expect(find.text('3 rows listed.'), findsOneWidget);
  });

  testWidgets('shows the table footer in Turkish', (tester) async {
    await pumpList(tester, items: const ['Grace Hopper'], isLoading: false, locale: const Locale('tr'));

    expect(find.text('1 satır listelendi.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Önceki'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Sonraki'), findsOneWidget);
  });

  testWidgets('shows the phone footer and the default create label in Turkish', (tester) async {
    await pumpList(
      tester,
      items: const ['Grace Hopper'],
      isLoading: false,
      size: const Size(390, 844),
      locale: const Locale('tr'),
      onCreateNew: () {},
    );

    expect(find.text('1 satır listelendi.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Yeni'), findsOneWidget);
  });

  testWidgets('puts the create button at the right edge of a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: AppResponsiveListView<String>(
            title: 'Users',
            items: const [],
            onCreateNew: () {},
            createLabel: 'New',
            columns: [AppTableColumn<String>(label: 'Name', flex: 1, builder: (_, item) => Text(item))],
            mobileCardBuilder: (_, item) => Text(item),
          ),
        ),
      ),
    );
    await tester.pump();

    // The header has 16 px of padding on each side.
    expect(tester.getRect(find.byType(FilledButton)).right, 390 - 16);
  });

  for (final textScale in [1.0, 1.3]) {
    testWidgets('fits a long title and create label on a 320 px wide phone at text scale $textScale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: AppResponsiveListView<String>(
              title: 'Kullanıcılar',
              items: const ['Grace Hopper'],
              onCreateNew: () {},
              createLabel: 'Yeni Kullanıcı Ekle',
              columns: [AppTableColumn<String>(label: 'Name', flex: 1, builder: (_, item) => Text(item))],
              mobileCardBuilder: (_, item) => Text(item),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Yeni Kullanıcı Ekle'), findsOneWidget);
      expect(find.text('Grace Hopper'), findsOneWidget);
    });
  }
}
