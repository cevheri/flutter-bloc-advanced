import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/dashboard_model.dart';
import 'package:flutter_bloc_advance/data/repository/dashboard_repository.dart';
import 'package:flutter_bloc_advance/presentation/screen/dashboard/bloc/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/presentation/screen/dashboard/dashboard_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';

import '../../test_utils.dart';

class _StubDashboardRepo implements DashboardRepository {
  @override
  Future<DashboardModel> fetch() async {
    const json =
        '{"summary":[{"id":"leads","label":"Leads","value":120,"trend":8}],"activities":[],"quick_actions":[{"id":"qa1","label":"New Lead","icon":"person_add"}] }';
    return DashboardModel.fromJsonString(json);
  }
}

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  testWidgets('DashboardPage renders core sections', (tester) async {
    await tester.pumpWidget(
      AdaptiveTheme(
        light: ThemeData.light(),
        dark: ThemeData.dark(),
        initial: AdaptiveThemeMode.light,
        builder: (light, dark) => MaterialApp(
          theme: light,
          darkTheme: dark,
          locale: const Locale('en'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BlocProvider<DashboardCubit>(
            create: (_) => DashboardCubit(repository: _StubDashboardRepo())..load(),
            child: const Scaffold(body: DashboardPage()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });
}
