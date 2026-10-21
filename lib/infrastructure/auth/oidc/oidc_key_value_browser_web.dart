/// Web build of the browser storage adapters in `oidc_key_value.dart`: thin wrappers over `window.localStorage` and
/// `window.sessionStorage`.
///
/// A storage the browser refuses (blocked site data) throws from the browser call itself; it is not caught here.
library;

import 'package:web/web.dart' as web;

import 'oidc_key_value.dart';

/// The origin's `localStorage`, shared by every tab and kept across reloads.
OidcKeyValue browserLocalStorage() => _BrowserStorage(web.window.localStorage);

/// This tab's `sessionStorage`, kept across reloads of the tab and seen by no other tab.
OidcKeyValue browserSessionStorage() => _BrowserStorage(web.window.sessionStorage);

final class _BrowserStorage implements OidcKeyValue {
  _BrowserStorage(this._storage);

  final web.Storage _storage;

  @override
  String? read(String key) => _storage.getItem(key);

  @override
  void write(String key, String value) => _storage.setItem(key, value);

  @override
  void delete(String key) => _storage.removeItem(key);

  @override
  Iterable<String> get keys => [for (var i = 0; i < _storage.length; i++) ?_storage.key(i)];
}
