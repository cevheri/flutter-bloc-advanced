import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the mock asset naming convention.
///
/// `MockInterceptor` builds the asset name from the request path by replacing `/` and `-` with `_`, so
/// `POST /account/change-password` looks for `POST_account_change_password.json`. A file whose name keeps a `-`
/// can never be found: the interceptor fails the request with 501 instead.
void main() {
  test('mock asset names use underscores instead of hyphens', () {
    final offenders = Directory('assets/mock')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.contains('-'))
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'MockInterceptor maps "-" in request paths to "_", so these files are never served.\n'
          'Rename them with underscores:\n${offenders.join('\n')}',
    );
  });
}
