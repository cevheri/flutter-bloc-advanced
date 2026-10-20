import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the macOS App Sandbox network entitlement.
///
/// The macOS runner is sandboxed (`com.apple.security.app-sandbox`), and the
/// sandbox blocks outgoing connections unless the app declares
/// `com.apple.security.network.client`. Without it every dio, Sentry and
/// `NetworkImage` request fails at runtime with
/// `SocketException: Connection failed (OS Error: Operation not permitted, errno = 1)`,
/// see https://docs.flutter.dev/platform-integration/macos/building#entitlements-and-the-app-sandbox.
///
/// The `flutter create` macOS template ships both files without this key and
/// no CI job builds macOS, so this meta-test fails if the key is dropped again.
void main() {
  test('both macOS entitlement files allow outgoing network connections', () {
    const entitlementFiles = ['macos/Runner/DebugProfile.entitlements', 'macos/Runner/Release.entitlements'];
    // A key inside an XML comment grants nothing, so comments are removed before matching.
    final xmlComment = RegExp(r'<!--.*?-->', dotAll: true);
    final networkClient = RegExp(r'<key>com\.apple\.security\.network\.client</key>\s*<true/>');

    final offenders = entitlementFiles
        .where((path) => !networkClient.hasMatch(File(path).readAsStringSync().replaceAll(xmlComment, '')))
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'These entitlement files do not set com.apple.security.network.client to true, '
          'so the sandboxed macOS app cannot reach its API:\n${offenders.join('\n')}',
    );
  });
}
