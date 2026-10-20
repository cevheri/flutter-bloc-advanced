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
}
