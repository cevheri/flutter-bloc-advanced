/// Reloads the web page when the browser restores it from its back-forward cache after the same-tab sign-in left it.
///
/// The tab leaves for the provider with the login page waiting for the answer. When the user presses Back on the
/// provider page, a browser may restore that page as it was instead of loading it again: the startup step never sees
/// the abandoned sign-in, and the SSO button stays disabled. A reload runs the startup step, which reports a cancel.
///
/// The browser listener is imported only on web, as `oidc_key_value.dart` does for the browser storage; other builds
/// have no page to restore, so their stub registers nothing.
library;

import 'package:flutter_bloc_advance/core/logging/app_logger.dart';

export 'oidc_page_restore_stub.dart'
    if (dart.library.js_interop) 'oidc_page_restore_web.dart'
    show reloadWhenRestoredFromCache;

final _log = AppLogger.getLogger('OidcPageRestore');

/// Handles a `pageshow` event: calls [reload] when the page came from the back-forward cache ([persisted]).
void onPageShow({required bool persisted, required void Function() reload}) {
  if (!persisted) return;
  _log.info('The page came back from the back-forward cache after a sign-in left it, so it is reloaded');
  reload();
}
