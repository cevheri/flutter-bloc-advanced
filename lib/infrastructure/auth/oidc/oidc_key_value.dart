/// The string key-value storage under the OIDC transaction store: the browser's `localStorage` or `sessionStorage` on
/// web, and memory elsewhere.
///
/// The browser adapters are imported only on web, where `dart:js_interop` is available, as
/// `transport_errors.dart` does for `dart:io`; other builds get a stub that throws.
library;

export 'oidc_key_value_browser_stub.dart'
    if (dart.library.js_interop) 'oidc_key_value_browser_web.dart'
    show browserLocalStorage, browserSessionStorage;

/// A synchronous string store, the shape of the browser's `Storage`.
abstract interface class OidcKeyValue {
  /// The value under [key], or null when there is none.
  String? read(String key);

  void write(String key, String value);

  /// Removes [key]; removing a missing key does nothing.
  void delete(String key);

  /// Every key currently stored.
  Iterable<String> get keys;
}

/// An [OidcKeyValue] that lives only as long as the app run.
final class MemoryKeyValue implements OidcKeyValue {
  MemoryKeyValue();

  final _values = <String, String>{};

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) => _values[key] = value;

  @override
  void delete(String key) => _values.remove(key);

  @override
  Iterable<String> get keys => List.unmodifiable(_values.keys);
}
