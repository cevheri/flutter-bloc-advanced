@Tags(['widget'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_env.dart';

void main() {
  // The bootstrap empties the rootBundle cache before every test, also in a file that opts out of TestEnv.reset as this
  // one does. Otherwise the second testWidgets would wait forever on the asset Future that the first one created in
  // its FakeAsync zone. The result is checked after pumping instead of awaited, so a regression fails at once.
  setUpAll(() => TestEnv.autoReset = false);

  for (final run in const ['first', 'second']) {
    testWidgets('loads a mock asset in the $run testWidgets of a file that opts out of the reset', (tester) async {
      String? json;
      unawaited(rootBundle.loadString('assets/mock/GET_account.json').then((value) => json = value));
      await tester.pump();

      expect(json, isNotNull, reason: 'the asset load never completed');
      expect(jsonDecode(json!), containsPair('login', 'admin'));
    });
  }

  // testWidgets passes the binding's defaultTestTimeout to test(), and package:test merges a test's timeout into the
  // one configured for it as Timeout.merge does: a duration replaces the configured timeout, a factor scales it.
  // A factor of 1, not a fixed 30 seconds, so a file-level @Timeout, a tag or --timeout still reaches testWidgets.
  test('a testWidgets keeps the configured timeout instead of its own 10 minutes', () {
    final defaultTestTimeout = AutomatedTestWidgetsFlutterBinding.instance.defaultTestTimeout;

    expect(defaultTestTimeout, const Timeout.factor(1));
    for (final configured in const [Timeout(Duration(seconds: 30)), Timeout(Duration(minutes: 5))]) {
      expect(configured.merge(defaultTestTimeout), configured);
    }
  });
}
