@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/utils/external_link.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/url_launcher_stub.dart';

void main() {
  const url = 'https://example.com/docs';

  Future<void> pumpLinkButton(WidgetTester tester) async {
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
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => openExternalLink(context, Uri.parse(url)), child: const Text('Docs')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('openExternalLink', () {
    for (final failure in UrlLauncherFailure.values) {
      testWidgets('tries to open the link and names it in a message when ${failure.description}', (tester) async {
        final calls = stubFailingUrlLauncher(failure);
        await pumpLinkButton(tester);
        final l10n = S.of(tester.element(find.byType(TextButton)));

        final addedTexts = await expectTapShowsMessage(tester, find.byType(TextButton));
        expect(addedTexts, [l10n.error_link_open_failed(url)]);
        expect(calls.launchedUrls, [url]);
      });
    }

    for (final canLaunch in [true, false]) {
      testWidgets('opens the link and shows no message when canLaunchUrl answers $canLaunch', (tester) async {
        final calls = stubOpeningUrlLauncher(canLaunch: canLaunch);
        await pumpLinkButton(tester);

        await expectTapShowsNoMessage(tester, find.byType(TextButton));
        expect(calls.launchedUrls, [url]);
      });
    }
  });
}
