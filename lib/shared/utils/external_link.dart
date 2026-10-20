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
