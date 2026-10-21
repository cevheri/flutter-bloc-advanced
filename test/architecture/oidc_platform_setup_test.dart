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
///   namespaces must match the package code, so it is copied and carries one documented patch only: the error branch
///   shows fixed copy instead of the provider's `error_description` and `error_uri`, because a crafted link to the
///   page sets both and provider text must never reach the screen.
/// - The app is a public PKCE client, so nothing in `lib/` reads a client secret.
/// - The app's own manifest declares no intent filter for the redirect scheme: a second one would let Android offer
///   `MainActivity` for the callback, and the package's redirect activity would no longer receive it.
void main() {
  group('OIDC platform setup', () {
    test('the Android manifest placeholder carries the default redirect scheme', () {
      const gradlePath = 'android/app/build.gradle.kts';
      final defaultConfig = _block(_stripLineComments(File(gradlePath).readAsStringSync()), 'defaultConfig');
      expect(defaultConfig, isNotNull, reason: '$gradlePath has no defaultConfig block');

      expect(
        defaultConfig,
        contains('manifestPlaceholders["oidcRedirectScheme"] = "${OidcSettings.defaultRedirectScheme}"'),
        reason:
            'defaultConfig in $gradlePath must set the oidcRedirectScheme manifest placeholder to '
            '${OidcSettings.defaultRedirectScheme}, or the oidc_android manifest merge fails and the redirect '
            'never reaches the app',
      );
    });

    test('web/redirect.html is the oidc package page with the documented error patch', () {
      final packagePath = '${_packageRoot('oidc').toFilePath()}example/web/redirect.html';
      final packagePage = File(packagePath).readAsStringSync();

      expect(
        _errorBranchOriginal.allMatches(packagePage).length,
        1,
        reason:
            '$packagePath must contain the error branch the patch replaces exactly once. After an oidc upgrade, '
            'find the branch that renders the parsed error and update _errorBranchOriginal and '
            '_errorBranchReplacement.',
      );
      expect(
        File('web/redirect.html').readAsStringSync(),
        packagePage.replaceFirst(_errorBranchOriginal, _errorBranchReplacement),
        reason:
            'web/redirect.html must be $packagePath with _errorBranchOriginal replaced by _errorBranchReplacement. '
            'After an oidc upgrade, copy example/web/redirect.html again with cp and re-apply that replacement; '
            'never edit the page otherwise.',
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

/// The package page's error branch, which renders the provider's `error_description` (or `error`) and `error_uri`.
const _errorBranchOriginal =
    "                    finish('error', messages.errorTitle, errorInfo.description || errorInfo.error, errorInfo.uri, "
    "true);\n";

/// The patched error branch in `web/redirect.html`: fixed copy and no link, since a crafted URL sets both values.
const _errorBranchReplacement =
    '                    // A crafted link sets error_description and error_uri, so show fixed copy and no link.\n'
    "                    finish('error', messages.errorTitle, messages.appError, null, true);\n";

/// Removes `//` comments that start a line or follow whitespace, so a `://` inside a string survives.
String _stripLineComments(String source) =>
    source.replaceAllMapped(RegExp(r'(^|\s)//[^\n]*', multiLine: true), (match) => match[1]!);

/// The body of the first `name { ... }` block in [source], matched by brace depth, or null when there is none.
String? _block(String source, String name) {
  final open = RegExp('\\b${RegExp.escape(name)}\\s*\\{').firstMatch(source);
  if (open == null) return null;

  var depth = 1;
  for (var i = open.end; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}' && --depth == 0) return source.substring(open.end, i);
  }
  fail('the $name block has no closing brace');
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
