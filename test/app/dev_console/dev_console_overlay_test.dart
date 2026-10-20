@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/dev_console/dev_console_overlay.dart';
import 'package:flutter_bloc_advance/app/dev_console/tabs/environment_tab.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  setUp(DevConsoleStore.instance.clearAll);
  tearDown(DevConsoleStore.instance.clearAll);

  // The real app, signed in on a phone, with the developer console open on its network tab. Signing in sends the
  // account request through the mock API, which the console captures. [extraEntries] are captured on top of it.
  Future<void> openConsole(
    WidgetTester tester, {
    required Size size,
    required String language,
    required double textScale,
    List<NetworkEntry> extraEntries = const [],
  }) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    TestEnv.authenticate();

    await tester.pumpWidget(App(language: language));
    await tester.pumpAndSettle();
    extraEntries.forEach(DevConsoleStore.instance.addNetworkEntry);
    DevConsoleOverlay.show(tester.element(find.byType(TopBarWidget)));
    // The pending request's spinner never settles, so the sheet's animation is pumped through instead.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  final start = DateTime(2026, 10, 20, 12, 34, 56);
  // A request that failed after a long wait, which shows every part of the row under the URL.
  final failed = NetworkEntry(
    id: 'failed',
    method: 'DELETE',
    url: 'https://api.example.com/api/admin/users/a-very-long-user-login-name?cacheBuster=1234567890',
    startTime: start,
    statusCode: 503,
    endTime: start.add(const Duration(milliseconds: 123456)),
    error: 'Service unavailable',
    responseHeaders: const {'content-type': 'application/json'},
  );
  final pending = NetworkEntry(
    id: 'pending',
    method: 'OPTIONS',
    url: 'https://api.example.com/api/x',
    startTime: start,
  );

  for (final language in const ['en', 'tr']) {
    for (final textScale in const [1.0, 1.3]) {
      for (final size in const [Size(320, 568), Size(360, 640), Size(375, 667)]) {
        final phone = '${size.width.toInt()}x${size.height.toInt()}';
        testWidgets('the console fits a $phone phone at text scale $textScale in $language', (tester) async {
          await openConsole(
            tester,
            size: size,
            language: language,
            textScale: textScale,
            extraEntries: [failed, pending],
          );
          expect(tester.takeException(), isNull, reason: 'title bar, tab bar, network toolbar and request rows');

          await tester.tap(find.textContaining('a-very-long-user-login-name'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull, reason: 'the details of an expanded request');

          for (final (index, tab) in const ['BLoC', 'Time Travel', 'Storage', 'Env'].indexed) {
            await tester.tap(find.text(tab));
            await tester.pump();
            await tester.pump(const Duration(seconds: 1));
            expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, index + 1, reason: '$tab is open');
            expect(tester.takeException(), isNull, reason: 'the $tab tab');
          }

          // The route tree sits below the fold when the text is large, and is only laid out once it is scrolled to.
          await tester.scrollUntilVisible(
            find.text('Current Route'),
            200,
            scrollable: find.descendant(of: find.byType(EnvironmentTab), matching: find.byType(Scrollable)),
          );
          expect(tester.takeException(), isNull, reason: 'the route tree');
        });
      }
    }
  }
}
