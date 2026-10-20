@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_skeleton.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_data_table.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_responsive_list_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDesktopList(WidgetTester tester, {required List<String>? items, required bool isLoading}) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppResponsiveListView<String>(
            title: 'Users',
            items: items,
            isLoading: isLoading,
            columns: [AppTableColumn<String>(label: 'Name', flex: 1, builder: (_, item) => Text(item))],
            mobileCardBuilder: (_, item) => Text(item),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows placeholder rows instead of an empty table while loading on a desktop', (tester) async {
    await pumpDesktopList(tester, items: null, isLoading: true);

    expect(find.byType(AppSkeleton), findsWidgets);
    expect(find.byType(AppDataTable<String>), findsNothing);
    expect(find.text('0 row(s) listed.'), findsNothing);
  });

  testWidgets('shows the table once loaded on a desktop', (tester) async {
    await pumpDesktopList(tester, items: const ['Grace Hopper'], isLoading: false);

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('1 row(s) listed.'), findsOneWidget);
    expect(find.byType(AppSkeleton), findsNothing);
  });

  testWidgets('puts the create button at the right edge of a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
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
