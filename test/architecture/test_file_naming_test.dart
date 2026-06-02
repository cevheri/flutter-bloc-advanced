import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the test-file naming convention.
///
/// `flutter test` only collects files whose name ends in `_test.dart`
/// (underscore). A file named `*.test.dart` (dot) still compiles and passes
/// `flutter analyze`, so it looks like coverage but is **never executed** —
/// an invisible class of test debt (see issue #147, where
/// `register_screen.test.dart` silently never ran).
///
/// This meta-test fails if any such dot-suffixed file reappears under `test/`.
void main() {
  test('no "*.test.dart" (dot) files — they are never run by `flutter test`', () {
    final offenders = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.replaceAll('\\', '/'))
        .where((p) => p.endsWith('.dart'))
        // Dot-suffixed test file: ends with `.test.dart` but NOT `_test.dart`.
        .where((p) => p.endsWith('.test.dart'))
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'These files use ".test.dart" (dot) and are NOT executed by `flutter test`.\n'
          'Rename them to end in "_test.dart":\n${offenders.join('\n')}',
    );
  });
}
