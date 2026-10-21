/// Web build of the listener in `oidc_page_restore.dart`: a `pageshow` listener on `window`.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'oidc_page_restore.dart';

/// Registers a `pageshow` listener that reloads the page when the browser restores it from the back-forward cache.
void reloadWhenRestoredFromCache() {
  web.window.addEventListener(
    'pageshow',
    (web.PageTransitionEvent event) {
      onPageShow(persisted: event.persisted, reload: web.window.location.reload);
    }.toJS,
  );
}
