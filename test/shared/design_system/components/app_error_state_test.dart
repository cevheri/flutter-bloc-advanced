@Tags(['widget'])
library;

import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppErrorState', () {
    // The component lives below the app's localizations, so it has no English text of its own to fall back on.
    test('asks for a retry label when it shows a retry button', () {
      expect(() => AppErrorState(title: 'Error', onRetry: () {}), throwsAssertionError);
    });

    test('needs no retry label without a retry button', () {
      expect(() => const AppErrorState(title: 'Error'), returnsNormally);
    });
  });
}
