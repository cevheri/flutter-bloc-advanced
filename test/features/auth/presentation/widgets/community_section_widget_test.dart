import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/testing/app_key_constants.dart';
import 'package:flutter_bloc_advance/features/auth/presentation/widgets/community_section_widget.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_utils.dart';

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  Widget buildWidget({required bool isDesktop}) {
    return MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: CommunitySectionWidget(isDesktop: isDesktop)),
      ),
    );
  }

  group('CommunitySectionWidget - Desktop', () {
    testWidgets('renders section title', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: true));
      await tester.pumpAndSettle();

      expect(find.text('Join the Community'), findsOneWidget);
    });

    testWidgets('renders Open Source pill badge', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: true));
      await tester.pumpAndSettle();

      expect(find.text('Open Source'), findsOneWidget);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: true));
      await tester.pumpAndSettle();

      expect(find.text('This project is open source. Your contributions make it better!'), findsOneWidget);
    });

    testWidgets('renders all 6 community action cards', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: true));
      await tester.pumpAndSettle();

      expect(find.byKey(communityStarKey), findsOneWidget);
      expect(find.byKey(communityIssueKey), findsOneWidget);
      expect(find.byKey(communityDiscussionsKey), findsOneWidget);
      expect(find.byKey(communityContributeKey), findsOneWidget);
      expect(find.byKey(communityTranslateKey), findsOneWidget);
      expect(find.byKey(communitySponsorKey), findsOneWidget);
    });

    testWidgets('displays correct label texts', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: true));
      await tester.pumpAndSettle();

      expect(find.text('Star & Fork'), findsOneWidget);
      expect(find.text('Open an Issue'), findsOneWidget);
      expect(find.text('Discussions'), findsOneWidget);
      expect(find.text('Contribute'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
      expect(find.text('Sponsor'), findsOneWidget);
    });
  });

  group('CommunitySectionWidget - Mobile', () {
    testWidgets('renders section title', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: false));
      await tester.pumpAndSettle();

      expect(find.text('Join the Community'), findsOneWidget);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: false));
      await tester.pumpAndSettle();

      expect(find.text('This project is open source. Your contributions make it better!'), findsOneWidget);
    });

    testWidgets('renders all 6 community chips', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: false));
      await tester.pumpAndSettle();

      expect(find.byKey(communityStarKey), findsOneWidget);
      expect(find.byKey(communityIssueKey), findsOneWidget);
      expect(find.byKey(communityDiscussionsKey), findsOneWidget);
      expect(find.byKey(communityContributeKey), findsOneWidget);
      expect(find.byKey(communityTranslateKey), findsOneWidget);
      expect(find.byKey(communitySponsorKey), findsOneWidget);
    });

    testWidgets('renders divider', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: false));
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('displays correct label texts', (tester) async {
      await tester.pumpWidget(buildWidget(isDesktop: false));
      await tester.pumpAndSettle();

      expect(find.text('Star & Fork'), findsOneWidget);
      expect(find.text('Open an Issue'), findsOneWidget);
      expect(find.text('Discussions'), findsOneWidget);
      expect(find.text('Contribute'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
      expect(find.text('Sponsor'), findsOneWidget);
    });
  });

  group('CommunityUrls', () {
    test('URLs are correctly defined', () {
      expect(CommunityUrls.repo, 'https://github.com/cevheri/flutter-bloc-advanced');
      expect(CommunityUrls.issues, 'https://github.com/cevheri/flutter-bloc-advanced/issues');
      expect(CommunityUrls.discussions, 'https://github.com/cevheri/flutter-bloc-advanced/discussions');
      expect(CommunityUrls.contributing, 'https://github.com/cevheri/flutter-bloc-advanced/blob/main/CONTRIBUTING.md');
      expect(CommunityUrls.translate, 'https://github.com/cevheri/flutter-bloc-advanced/tree/main/lib/l10n');
      expect(CommunityUrls.sponsor, 'https://github.com/sponsors/cevheri');
    });
  });
}
