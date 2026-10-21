import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:oidc/oidc.dart';

import 'oidc_key_value.dart';

/// The app-owned [OidcStore] of the OIDC user manager.
///
/// It keeps each namespace where the sign-in needs it and nowhere else:
/// - `state` at `oidc.state.<id>` and `stateResponse` at `oidc.response.state.<id>` in [persistent], each with its
///   JSON array index `oidc.keys.<namespace>`. That is the layout `web/redirect.html` reads and writes, so on web
///   [persistent] is `localStorage`: the page finds the state and stores the provider's redirect URL there.
/// - the PKCE `code_verifier.<id>` and the `nonce` of `secureTokens` in [tab], under `oidc.secureTokens.<key>`. On
///   web that is the tab's `sessionStorage`, so a sign-in survives the same-tab reload and stays with its tab.
/// - every other `secureTokens` key (the manager's copy of the tokens and claims), `discoveryDocument` and `request`
///   in a private map that lives only as long as this object. The app's session storage owns the tokens.
///
/// `request` never reads [persistent]: the `oidc.request.front-channel-logout` marker that redirect.html writes for a
/// crafted front-channel logout link would otherwise make the manager's `init()` skip the pending response.
/// `session` is unused by the manager and refused. The manager must keep its `id` null, which keeps every key in the
/// redirect.html layout, so a `managerId` is refused too.
///
/// `getAllKeys(stateResponse)` answers only the states whose verifier is in [tab], so one tab never consumes or
/// deletes the response to another tab's sign-in.
final class OidcTransactionStore implements OidcStore {
  OidcTransactionStore({required this._persistent, required this._tab});

  /// `localStorage` and `sessionStorage` on web; two [MemoryKeyValue]s elsewhere, where the sign-in completes
  /// within one app run.
  factory OidcTransactionStore.forPlatform() => kIsWeb
      ? OidcTransactionStore(persistent: browserLocalStorage(), tab: browserSessionStorage())
      : OidcTransactionStore(persistent: MemoryKeyValue(), tab: MemoryKeyValue());

  static const _prefix = 'oidc';
  static const _codeVerifierPrefix = '${OidcConstants_AuthParameters.codeVerifier}.';
  static const _nonceKey = OidcConstants_AuthParameters.nonce;
  static const _tabPrefix = '$_prefix.secureTokens.';

  final OidcKeyValue _persistent;
  final OidcKeyValue _tab;
  final _memory = <OidcStoreNamespace, Map<String, String>>{};

  @override
  Future<void> init() async {}

  @override
  Future<Set<String>> getAllKeys(OidcStoreNamespace namespace, {String? managerId}) async {
    _checkManagerId(managerId);
    return switch (namespace) {
      OidcStoreNamespace.state => _index(namespace),
      OidcStoreNamespace.stateResponse => _index(namespace).intersection(_tabVerifierStates()),
      OidcStoreNamespace.secureTokens => {..._tabKeys(), ..._memoryOf(namespace).keys},
      OidcStoreNamespace.request || OidcStoreNamespace.discoveryDocument => _memoryOf(namespace).keys.toSet(),
      OidcStoreNamespace.session => throw _sessionUnsupported(),
    };
  }

  @override
  Future<Map<String, String>> getMany(
    OidcStoreNamespace namespace, {
    required Set<String> keys,
    String? managerId,
  }) async {
    _checkManagerId(managerId);
    return {for (final key in keys) key: ?_read(namespace, key)};
  }

  @override
  Future<void> setMany(OidcStoreNamespace namespace, {required Map<String, String> values, String? managerId}) async {
    _checkManagerId(managerId);
    for (final MapEntry(:key, :value) in values.entries) {
      switch (namespace) {
        case OidcStoreNamespace.state || OidcStoreNamespace.stateResponse:
          _persistent.write(_entryKey(namespace, key), value);
          _writeIndex(namespace, {..._index(namespace), key});
        case OidcStoreNamespace.secureTokens when _isTabKey(key):
          _tab.write('$_tabPrefix$key', value);
        case OidcStoreNamespace.session:
          throw _sessionUnsupported();
        case _:
          _memoryOf(namespace)[key] = value;
      }
    }
  }

  @override
  Future<void> removeMany(OidcStoreNamespace namespace, {required Set<String> keys, String? managerId}) async {
    _checkManagerId(managerId);
    for (final key in keys) {
      _remove(namespace, key);
    }
  }

  /// Removes this tab's transactions: for every state whose verifier is in this tab, the state, its response and the
  /// verifier, and then this tab's nonce.
  ///
  /// Another tab's state and response stay; the manager's `clearUnusedStates` ages them out.
  Future<void> clearTransactions() async {
    for (final state in _tabVerifierStates()) {
      _remove(OidcStoreNamespace.secureTokens, '$_codeVerifierPrefix$state');
      _remove(OidcStoreNamespace.state, state);
      _remove(OidcStoreNamespace.stateResponse, state);
    }
    _remove(OidcStoreNamespace.secureTokens, _nonceKey);
  }

  /// Whether a stored response answers a sign-in this tab started.
  Future<bool> hasPendingResponse() async {
    final states = await getAllKeys(OidcStoreNamespace.stateResponse);
    return states.any((state) => _read(OidcStoreNamespace.stateResponse, state) != null);
  }

  /// Whether this tab holds a verifier whose state has no stored response: the tab left for the provider and came
  /// back without an answer, such as with the browser's Back button.
  bool hasAbandonedSignIn() =>
      _tabVerifierStates().any((state) => _read(OidcStoreNamespace.stateResponse, state) == null);

  String? _read(OidcStoreNamespace namespace, String key) => switch (namespace) {
    OidcStoreNamespace.state || OidcStoreNamespace.stateResponse => _persistent.read(_entryKey(namespace, key)),
    OidcStoreNamespace.secureTokens when _isTabKey(key) => _tab.read('$_tabPrefix$key'),
    OidcStoreNamespace.session => throw _sessionUnsupported(),
    _ => _memoryOf(namespace)[key],
  };

  void _remove(OidcStoreNamespace namespace, String key) {
    switch (namespace) {
      case OidcStoreNamespace.state || OidcStoreNamespace.stateResponse:
        _persistent.delete(_entryKey(namespace, key));
        final index = _index(namespace);
        if (index.remove(key)) _writeIndex(namespace, index);
      case OidcStoreNamespace.secureTokens when _isTabKey(key):
        _tab.delete('$_tabPrefix$key');
      case OidcStoreNamespace.session:
        throw _sessionUnsupported();
      case _:
        _memoryOf(namespace).remove(key);
    }
  }

  Map<String, String> _memoryOf(OidcStoreNamespace namespace) => _memory[namespace] ??= {};

  static bool _isTabKey(String key) => key == _nonceKey || key.startsWith(_codeVerifierPrefix);

  /// The `secureTokens` keys held in [_tab], without the storage prefix.
  Iterable<String> _tabKeys() =>
      _tab.keys.where((key) => key.startsWith(_tabPrefix)).map((key) => key.substring(_tabPrefix.length));

  /// The states this tab started: those whose verifier is in [_tab].
  Set<String> _tabVerifierStates() => {
    for (final key in _tabKeys())
      if (key.startsWith(_codeVerifierPrefix)) key.substring(_codeVerifierPrefix.length),
  };

  static String _entryKey(OidcStoreNamespace namespace, String key) => '$_prefix.${namespace.value}.$key';

  static String _indexKey(OidcStoreNamespace namespace) => '$_prefix.keys.${namespace.value}';

  /// The ids in the JSON array index of [namespace]. redirect.html appends without removing duplicates, so they are
  /// read as a set.
  Set<String> _index(OidcStoreNamespace namespace) {
    final raw = _persistent.read(_indexKey(namespace));
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.any((id) => id is! String)) {
      throw FormatException('${_indexKey(namespace)} is not a JSON array of strings');
    }
    return decoded.cast<String>().toSet();
  }

  void _writeIndex(OidcStoreNamespace namespace, Set<String> ids) =>
      _persistent.write(_indexKey(namespace), jsonEncode(ids.toList()));

  static void _checkManagerId(String? managerId) {
    if (managerId != null) {
      throw ArgumentError.value(managerId, 'managerId', 'must be null to keep the redirect.html key layout');
    }
  }

  static UnsupportedError _sessionUnsupported() => UnsupportedError('the session namespace is not used');
}
