import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// How url_launcher reports a link that does not open.
///
/// `canLaunchUrl` answers false when no app is registered for the link, and true when one is registered even if it
/// then fails to open the link, so a link that does not open can come with either answer. `launchUrl` reports the
/// failure either by returning false or by throwing a [PlatformException], depending on the platform and the cause.
class UrlLauncherFailure {
  const UrlLauncherFailure({required this.canLaunch, required this.launchThrows});

  /// Every combination of the two answers.
  static const values = [
    UrlLauncherFailure(canLaunch: false, launchThrows: true),
    UrlLauncherFailure(canLaunch: false, launchThrows: false),
    UrlLauncherFailure(canLaunch: true, launchThrows: true),
    UrlLauncherFailure(canLaunch: true, launchThrows: false),
  ];

  final bool canLaunch;
  final bool launchThrows;

  String get description =>
      'canLaunchUrl answers $canLaunch and launchUrl ${launchThrows ? 'throws' : 'returns false'}';
}

/// The calls the app makes to url_launcher during a test, in order.
class UrlLauncherCalls {
  /// Every URL the app passes to `canLaunchUrl` or `launchUrl`.
  final requestedUrls = <String>[];

  /// The URLs the app passes to `launchUrl`, that is, tries to open.
  final launchedUrls = <String>[];
}

/// Answers url_launcher's method channel like a device on which links do not open, as [failure] describes, and
/// returns the calls the app makes to url_launcher.
UrlLauncherCalls stubFailingUrlLauncher(UrlLauncherFailure failure) => _stubUrlLauncher(
  canLaunch: failure.canLaunch,
  launch: () => failure.launchThrows
      ? throw PlatformException(code: 'ACTIVITY_NOT_FOUND', message: 'No Activity found to handle intent')
      : false,
);

/// Answers url_launcher's method channel like a device on which every link opens, with `canLaunchUrl` answering
/// [canLaunch], and returns the calls the app makes to url_launcher.
///
/// `canLaunchUrl` can answer false for a link that `launchUrl` opens: on Android 11 and higher for a scheme the
/// manifest does not list in `<queries>`, and on iOS for a scheme missing from `LSApplicationQueriesSchemes`.
UrlLauncherCalls stubOpeningUrlLauncher({required bool canLaunch}) =>
    _stubUrlLauncher(canLaunch: canLaunch, launch: () => true);

/// `flutter test` does not register url_launcher's platform implementations, so the plugin talks to its default
/// `plugins.flutter.io/url_launcher` channel, which has no handler unless a test installs one. The handler is removed
/// when the test ends.
UrlLauncherCalls _stubUrlLauncher({required bool canLaunch, required bool Function() launch}) {
  final calls = UrlLauncherCalls();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'canLaunch':
        calls.requestedUrls.add((call.arguments as Map)['url'] as String);
        return canLaunch;
      case 'launch':
        final url = (call.arguments as Map)['url'] as String;
        calls.requestedUrls.add(url);
        calls.launchedUrls.add(url);
        return launch();
      default:
        throw MissingPluginException('The url_launcher stub does not answer ${call.method}');
    }
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  return calls;
}

/// Taps [target], expects the user to see a message that was not on screen before the tap, and returns the texts the
/// tap added.
///
/// Any added [Text] or [SelectableText] the user can see counts, so the check holds whether the message is a snack
/// bar, a toast, a dialog or inline text, and also when it repeats a text that is already on screen. A text covered
/// by a drawer, a barrier or another route does not count. Afterwards it waits for a snack bar or toast to time out,
/// so no timer outlives the test.
Future<List<String>> expectTapShowsMessage(WidgetTester tester, Finder target) async {
  final addedTexts = await _textsAddedByTap(tester, target);
  expect(addedTexts, isNotEmpty, reason: 'The tap showed the user no message.');

  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
  return addedTexts;
}

/// Taps [target] and expects no text to appear that was not on screen before the tap.
Future<void> expectTapShowsNoMessage(WidgetTester tester, Finder target) async {
  final addedTexts = await _textsAddedByTap(tester, target);
  expect(addedTexts, isEmpty, reason: 'The tap showed the user a message.');

  await tester.pumpAndSettle();
}

/// Taps [target] and returns the texts on screen a second later that were not on screen before the tap.
Future<List<String>> _textsAddedByTap(WidgetTester tester, Finder target) async {
  final textsBefore = _visibleTexts(tester);

  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));

  final addedTexts = _visibleTexts(tester);
  for (final text in textsBefore) {
    addedTexts.remove(text);
  }
  return addedTexts;
}

// Only texts the user can see: hitTestable() drops a text that a drawer, a modal barrier or another route covers.
List<String> _visibleTexts(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text).hitTestable()))
    text.data ?? text.textSpan!.toPlainText(),
  for (final text in tester.widgetList<SelectableText>(find.byType(SelectableText).hitTestable()))
    text.data ?? text.textSpan!.toPlainText(),
];
