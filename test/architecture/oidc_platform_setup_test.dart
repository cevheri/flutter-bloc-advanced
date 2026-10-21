import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc_advance/infrastructure/config/auth_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the platform setup the `oidc` package needs.
///
/// - The `oidc_android` plugin merges an `OidcRedirectActivity` whose intent filter uses the `oidcRedirectScheme`
///   manifest placeholder. The placeholder has no default, so the manifest merge fails without it, and it must match
///   the scheme the Dart side sends as its redirect URI.
/// - `web/redirect.html` is the page the package ships at `example/web/redirect.html`. Its channel names and store
///   namespaces must match the package code, so it is copied byte for byte and never edited.
/// - The app is a public PKCE client, so nothing in `lib/` reads a client secret.
/// - The app's own manifest declares no intent filter for the redirect scheme: a second one would let Android offer
///   `MainActivity` for the callback, and the package's redirect activity would no longer receive it.
void main() {
  group('OIDC platform setup', () {
    test('the Android manifest placeholder carries the default redirect scheme', () {
      const gradlePath = 'android/app/build.gradle.kts';
      final defaultConfig = RegExp(r'defaultConfig\s*\{([^}]*)\}')
          .firstMatch(File(gradlePath).readAsStringSync().replaceAll(RegExp(r'//[^\n]*'), ''));
      expect(defaultConfig, isNotNull, reason: '$gradlePath has no defaultConfig block');

      expect(
        defaultConfig![1],
        contains('manifestPlaceholders["oidcRedirectScheme"] = "${OidcSettings.defaultRedirectScheme}"'),
        reason:
            'defaultConfig in $gradlePath must set the oidcRedirectScheme manifest placeholder to '
            '${OidcSettings.defaultRedirectScheme}, or the oidc_android manifest merge fails and the redirect '
            'never reaches the app',
      );
    });

    test('web/redirect.html is the oidc package page, byte for byte', () {
      final packagePage = File('${_packageRoot('oidc').toFilePath()}example/web/redirect.html');

      expect(
        File('web/redirect.html').readAsBytesSync(),
        packagePage.readAsBytesSync(),
        reason:
            'web/redirect.html differs from ${packagePage.path}. After an oidc upgrade, copy the package page '
            'again with cp; never edit it by hand.',
      );
    });

    test('no client secret is read anywhere in lib', () {
      final secret = RegExp('client_secret|OIDC_CLIENT_SECRET', caseSensitive: false);

      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => secret.hasMatch(file.readAsStringSync()))
          .map((file) => file.path)
          .toList();

      expect(
        offenders,
        isEmpty,
        reason: 'The app is a public PKCE client and must not read a client secret:\n${offenders.join('\n')}',
      );
    });

    test('the app declares no intent filter for the redirect scheme', () {
      const manifestPath = 'android/app/src/main/AndroidManifest.xml';

      expect(
        File(manifestPath).readAsStringSync(),
        isNot(contains(OidcSettings.defaultRedirectScheme)),
        reason:
            '$manifestPath must not mention ${OidcSettings.defaultRedirectScheme}: the OidcRedirectActivity of '
            'oidc_android owns that scheme',
      );
    });
  });
}

/// The root folder of [package], read from `.dart_tool/package_config.json`, with a trailing slash.
Uri _packageRoot(String package) {
  const configPath = '.dart_tool/package_config.json';
  final config = jsonDecode(File(configPath).readAsStringSync()) as Map<String, dynamic>;
  final entry = (config['packages'] as List<dynamic>).cast<Map<String, dynamic>>().where(
    (entry) => entry['name'] == package,
  );
  if (entry.isEmpty) fail('$configPath has no entry for $package; run fvm flutter pub get');

  final root = File(configPath).absolute.uri.resolve(entry.single['rootUri'] as String);
  return root.path.endsWith('/') ? root : root.replace(path: '${root.path}/');
}
