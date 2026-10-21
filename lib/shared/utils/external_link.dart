import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = AppLogger.getLogger('ExternalLink');

/// Opens [uri] outside the app, in the browser or the app that handles it, and shows a snack bar naming the link
/// when it does not open.
///
/// It calls `launchUrl` without asking `canLaunchUrl` first, as the url_launcher README advises: `canLaunchUrl`
/// answers false for a scheme the app does not declare, even when `launchUrl` would open the link. `launchUrl` reports
/// a link that does not open either by returning false or by throwing a [PlatformException], depending on the
/// platform and the cause, so both are handled as the same failure.
Future<void> openExternalLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = S.of(context);
  Object failure;
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    failure = 'launchUrl returned false';
  } on PlatformException catch (e) {
    failure = e;
  }
  _log.warn('Could not open {}: {}', [uri, failure]);
  messenger.showSnackBar(SnackBar(content: Text(l10n.error_link_open_failed(uri.toString()))));
}

/// Opens [uri] in the browser for a flow that has no [BuildContext], such as the desktop OpenID Connect sign-in, and
/// answers true.
///
/// It has the `Future<bool> Function(Uri)` shape of the oidc package's `launchUrl` option, but never answers false:
/// the package logs the whole URL, with its `state` and `nonce`, when a launcher does. A link that does not open
/// throws a [StateError] instead, whether `launchUrl` returned false or threw a [PlatformException], whose message
/// can repeat the link; the error names only the platform's error code.
Future<bool> launchExternalUri(Uri uri) async {
  final bool opened;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException catch (e) {
    throw StateError('The browser did not open the link (${e.code})');
  }
  if (!opened) throw StateError('The browser did not open the link');
  return true;
}
