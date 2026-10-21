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
///   namespaces must match the package code, so it is copied and carries three documented patches only: the error
///   branch shows fixed copy instead of the provider's `error_description` and `error_uri`, because a crafted link to
///   the page sets both and provider text must never reach the screen; a missing state is logged without its value;
///   and the page returns to the app with `location.replace`, so the callback URL never stays in the tab history.
/// - The app is a public PKCE client, so nothing in `lib/` names a client secret and every client authentication is
///   `OidcClientAuthentication.none`.
/// - No app manifest declares an intent filter for the redirect scheme: a second one would let Android offer
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

    test('web/redirect.html is the oidc package page with the documented patches', () {
      final packagePath = '${_packageRoot('oidc').toFilePath()}example/web/redirect.html';
      final packagePage = File(packagePath).readAsStringSync();

      for (final patch in _redirectPagePatches) {
        expect(
          patch.original.allMatches(packagePage).length,
          1,
          reason:
              '$packagePath must contain the snippet the ${patch.name} patch replaces exactly once. After an oidc '
              'upgrade, find that snippet in the new page and update the patch in _redirectPagePatches.',
        );
      }
      expect(
        File('web/redirect.html').readAsStringSync(),
        _redirectPagePatches.fold(packagePage, (page, patch) => page.replaceFirst(patch.original, patch.replacement)),
        reason:
            'web/redirect.html must be $packagePath with the patches ${_redirectPagePatches.map((p) => p.name).join(', ')} '
            'of _redirectPagePatches applied. After an oidc upgrade, copy example/web/redirect.html again with cp and '
            're-apply those replacements; never edit the page otherwise.',
      );
    });

    test('the client secret pattern flags the spellings of the oidc package', () {
      for (final spelling in [
        'clientSecretPost(',
        'clientSecretBasic(',
        'clientSecret:',
        'client_secret',
        'OIDC_CLIENT_SECRET',
      ]) {
        expect(_clientSecret.hasMatch(spelling), isTrue, reason: 'the pattern misses $spelling');
      }
    });

    test('no client secret is named anywhere in lib', () {
      final offenders = <String>[];
      for (final file in _dartFiles('lib')) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!_clientSecret.hasMatch(lines[i])) continue;
          // The scrubber's doc comment names `clientSecret` as a key it masks; it reads no secret.
          if (file.path == _scrubberPath && lines[i].trimLeft().startsWith('///')) continue;
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'The app is a public PKCE client and must not name a client secret:\n${offenders.join('\n')}',
      );
    });

    test('every client authentication in lib is OidcClientAuthentication.none', () {
      final constructions = <String>[];
      final offenders = <String>[];
      for (final file in _dartFiles('lib')) {
        for (final match in RegExp(r'OidcClientAuthentication\s*\.\s*(\w+)').allMatches(file.readAsStringSync())) {
          constructions.add(file.path);
          if (match[1] != 'none') offenders.add('${file.path}: OidcClientAuthentication.${match[1]}');
        }
      }

      expect(constructions, isNotEmpty, reason: 'lib/ builds no OidcClientAuthentication; the guard looks in vain');
      expect(
        offenders,
        isEmpty,
        reason: 'The app is a public PKCE client, so its client authentication is .none:\n${offenders.join('\n')}',
      );
    });

    test('no app manifest declares an intent filter for the redirect scheme', () {
      final manifests = Directory('android/app/src')
          .listSync()
          .whereType<Directory>()
          .map((dir) => File('${dir.path}/AndroidManifest.xml'))
          .where((file) => file.existsSync())
          .toList();
      expect(
        manifests.map((file) => file.path),
        contains('android/app/src/main/AndroidManifest.xml'),
        reason: 'the guard found no main manifest under android/app/src',
      );

      final offenders = <String>[
        for (final manifest in manifests)
          for (final needle in [OidcSettings.defaultRedirectScheme, 'oidcRedirectScheme'])
            if (manifest.readAsStringSync().contains(needle)) '${manifest.path} mentions $needle',
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            'No app manifest may mention ${OidcSettings.defaultRedirectScheme} or the oidcRedirectScheme placeholder: '
            'the OidcRedirectActivity of oidc_android owns that scheme:\n${offenders.join('\n')}',
      );
    });
  });
}

/// Matches every spelling of a client secret: `client_secret`, `OIDC_CLIENT_SECRET`, and the package's camelCase
/// `clientSecret`, `clientSecretBasic` and `clientSecretPost`.
final _clientSecret = RegExp('client_?secret', caseSensitive: false);

/// The one file in `lib/` whose doc comment may name a client secret.
const _scrubberPath = 'lib/core/security/sensitive_data_scrubber.dart';

/// Every Dart file under [root].
Iterable<File> _dartFiles(String root) =>
    Directory(root).listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));

/// One documented replacement that turns the package's redirect page into `web/redirect.html`.
typedef _Patch = ({String name, String original, String replacement});

/// The patches of `web/redirect.html`, applied in order to the package page.
const List<_Patch> _redirectPagePatches = [
  // The package page renders the provider's `error_description` (or `error`) and `error_uri`; the patched branch
  // shows fixed copy and no link, since a crafted URL sets both values.
  (
    name: 'error-branch',
    original:
        "                    finish('error', messages.errorTitle, errorInfo.description || errorInfo.error, "
        'errorInfo.uri, true);\n',
    replacement:
        '                    // A crafted link sets error_description and error_uri, so show fixed copy and no link.\n'
        "                    finish('error', messages.errorTitle, messages.appError, null, true);\n",
  ),
  // The package page prints the state value it could not find; the patched line logs the fact only.
  (
    name: 'state-log',
    original: "                    console.error('state not found, key: ' + state);\n",
    replacement:
        '                    // The state value never reaches the console.\n'
        "                    console.error('state not found');\n",
  ),
  // The package page returns with `assign`, which keeps the callback URL with its code and state in the tab history;
  // `replace` drops that entry, so Back never reaches the page again.
  (
    name: 'history-replace',
    original: '                window.location.assign(original_uri);\n',
    replacement:
        '                // replace, not assign: the callback URL with its code and state leaves the tab history.\n'
        '                window.location.replace(original_uri);\n',
  ),
];

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
