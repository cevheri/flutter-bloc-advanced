import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';

import '../../../../test_utils.dart';

class _StubDashboardRepo implements IDashboardRepository {
  @override
  Future<Result<DashboardEntity>> fetch() async {
    return const Success(
      DashboardEntity(
        summary: [DashboardSummaryEntity(id: 'leads', label: 'Leads', value: 120, trend: 8)],
        activities: [],
        quickActions: [DashboardQuickActionEntity(id: 'qa1', label: 'New Lead', icon: 'person_add')],
      ),
    );
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
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
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
    );

    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });
}
