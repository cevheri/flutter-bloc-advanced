@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFormActions', () {
    testWidgets('puts the primary action under the secondary one when both do not fit on one line', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: AppFormActions(
                  secondaryAction: OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
                  primaryAction: FilledButton(onPressed: () {}, child: const Text('Create')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final secondary = tester.getRect(find.byType(OutlinedButton));
      final primary = tester.getRect(find.byType(FilledButton));
      expect(primary.top, greaterThan(secondary.bottom));
      expect(primary.right, secondary.right);
    });

    testWidgets('keeps both actions on one line, ending at the right edge, when they fit', (tester) async {
      const hostKey = Key('host');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: hostKey,
                width: 400,
                // A start-aligned column hands its children loose width, as a dialog or a form body does.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppFormActions(
                      secondaryAction: OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
                      primaryAction: FilledButton(onPressed: () {}, child: const Text('Create')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final secondary = tester.getRect(find.byType(OutlinedButton));
      final primary = tester.getRect(find.byType(FilledButton));
      expect(primary.top, secondary.top);
      expect(primary.left, greaterThan(secondary.right));
      expect(primary.right, tester.getRect(find.byKey(hostKey)).right);
    });
  });
}
