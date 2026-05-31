import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/dev_console/tabs/environment_tab.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Reproduces the crash where opening the dev-console Environment tab threw
/// "There is no GoRouterState above the current context". The tab is shown
/// from a modal bottom sheet, whose subtree is NOT under any GoRoute's
/// builder — so [GoRouterState.of] has no scope to resolve. The fix reads
/// the current location from the router itself (`GoRouter.of(c).state`).
void main() {
  setUp(() {
    ProfileConstants.setEnvironment(Environment.test);
  });

  GoRouter buildRouter() {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) => const SizedBox(height: 500, child: EnvironmentTab()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  testWidgets('EnvironmentTab renders inside a modal bottom sheet without a GoRouterState error', (tester) async {
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light(), routerConfig: buildRouter()));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'must not throw GoError from a context outside any route builder');
    expect(find.text('Current Route'), findsOneWidget);
    expect(find.text('/'), findsWidgets, reason: 'current location path is shown');
  });
}
