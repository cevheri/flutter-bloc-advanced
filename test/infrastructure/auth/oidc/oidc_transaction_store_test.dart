import 'dart:convert';

import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_key_value.dart';
import 'package:flutter_bloc_advance/infrastructure/auth/oidc/oidc_transaction_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;
import 'package:oidc/oidc.dart';

const _stateId = 'state-1';
const _stateData = '{"id":"state-1","original_uri":"http://localhost:8081/"}';
const _verifier = 'verifier-1';
const _nonce = 'nonce-1';
const _response = 'http://localhost:8081/redirect.html?code=code-1&state=state-1';

/// Stores [url] as the response to [state] the way redirect.html's `setLocalStorage` does: it appends the state to the
/// `oidc.keys.response.state` JSON array and writes the URL under `oidc.response.state.<state>`.
void _redirectHtmlStoresResponse(OidcKeyValue localStorage, String state, String url) {
  const indexKey = 'oidc.keys.response.state';
  final keys = jsonDecode(localStorage.read(indexKey) ?? '[]') as List<dynamic>;
  localStorage.write(indexKey, jsonEncode([...keys, state]));
  localStorage.write('oidc.response.state.$state', url);
}

/// Starts a sign-in in [store] the way the manager's `prepareAuthorizationCodeFlowRequest` does.
Future<void> _startSignIn(OidcTransactionStore store, {String state = _stateId}) async {
  await store.setStateCodeVerifier(state: state, codeVerifier: _verifier);
  await store.setStateData(state: state, stateData: _stateData);
  await store.setCurrentNonce(_nonce);
}

void main() {
  late MemoryKeyValue persistent;
  late MemoryKeyValue tab;
  late OidcTransactionStore store;

  setUp(() {
    persistent = MemoryKeyValue();
    tab = MemoryKeyValue();
    store = OidcTransactionStore(persistent: persistent, tab: tab);
  });

  test('state data uses the redirect.html key layout', () async {
    await _startSignIn(store);

    expect(persistent.read('oidc.state.$_stateId'), _stateData);
    expect(await store.getStateData(_stateId), _stateData);
    expect(await store.getAllKeys(OidcStoreNamespace.state), {_stateId});
  });

  test('the verifier and the nonce stay in the tab', () async {
    await _startSignIn(store);

    expect(tab.keys, unorderedEquals(['oidc.secureTokens.code_verifier.$_stateId', 'oidc.secureTokens.nonce']));
    expect(persistent.keys.where((key) => key.contains('secureTokens')), isEmpty);
    expect(await store.getStateCodeVerifier(_stateId), _verifier);
    expect(await store.getCurrentNonce(), _nonce);
  });

  test('a response written in the redirect.html layout is found', () async {
    await _startSignIn(store);
    _redirectHtmlStoresResponse(persistent, _stateId, _response);

    final pending = await store.getStatesWithResponses();

    expect(pending.keys, [_stateId]);
    expect(pending[_stateId]!.stateData, _stateData);
    expect(pending[_stateId]!.stateResponse, _response);
  });

  test('removing a response also drops it from the redirect.html index', () async {
    await _startSignIn(store);
    _redirectHtmlStoresResponse(persistent, 'other-tab', _response);
    _redirectHtmlStoresResponse(persistent, _stateId, _response);

    await store.removeStateResponseData(_stateId);

    expect(persistent.read('oidc.response.state.$_stateId'), isNull);
    expect(jsonDecode(persistent.read('oidc.keys.response.state')!), ['other-tab']);
  });

  test("another tab cannot see this tab's pending response", () async {
    final otherTab = OidcTransactionStore(persistent: persistent, tab: MemoryKeyValue());
    await _startSignIn(store);
    _redirectHtmlStoresResponse(persistent, _stateId, _response);

    expect(await otherTab.getAllKeys(OidcStoreNamespace.stateResponse), isEmpty);
    expect(await otherTab.getStatesWithResponses(), isEmpty);
    expect(await otherTab.hasPendingResponse(), isFalse);
    expect(await store.getStatesWithResponses(), hasLength(1));
  });

  test('tokens and discovery never reach persistent or tab storage', () async {
    await store.setMany(
      OidcStoreNamespace.secureTokens,
      values: {'currentToken': '{"access_token":"a"}', 'userInfo': '{}', 'userAttributes': '{}'},
    );
    await store.set(OidcStoreNamespace.discoveryDocument, key: 'https://id.example/.well-known', value: '{}');

    expect(persistent.keys, isEmpty);
    expect(tab.keys, isEmpty);
    expect(await store.get(OidcStoreNamespace.secureTokens, key: 'currentToken'), '{"access_token":"a"}');
    expect(await store.getAllKeys(OidcStoreNamespace.secureTokens), {'currentToken', 'userInfo', 'userAttributes'});
    expect(await store.getAllKeys(OidcStoreNamespace.discoveryDocument), {'https://id.example/.well-known'});

    await store.remove(OidcStoreNamespace.secureTokens, key: 'currentToken');
    expect(await store.get(OidcStoreNamespace.secureTokens, key: 'currentToken'), isNull);
  });

  test('a front-channel logout marker in persistent storage is not visible through the store', () async {
    // What redirect.html writes for a link with requestType=front-channel-logout.
    _redirectHtmlStoresResponse(persistent, _stateId, _response);
    persistent.write('oidc.keys.request', jsonEncode(['front-channel-logout']));
    persistent.write('oidc.request.front-channel-logout', 'http://localhost:8081/redirect.html?requestType=x');

    expect(await store.getAllKeys(OidcStoreNamespace.request), isEmpty);
    expect(await store.getCurrentFrontChannelLogoutRequest(), isNull);

    await store.setCurrentFrontChannelLogoutRequest('in-memory');
    expect(await store.getCurrentFrontChannelLogoutRequest(), 'in-memory');
    expect(persistent.read('oidc.request.front-channel-logout'), 'http://localhost:8081/redirect.html?requestType=x');
  });

  test('clearTransactions removes states, responses, verifiers and the nonce', () async {
    await _startSignIn(store);
    await _startSignIn(store, state: 'state-2');
    _redirectHtmlStoresResponse(persistent, _stateId, _response);
    await store.set(OidcStoreNamespace.secureTokens, key: 'currentToken', value: '{}');

    await store.clearTransactions();

    expect(persistent.keys.where((key) => !key.startsWith('oidc.keys.')), isEmpty);
    expect(jsonDecode(persistent.read('oidc.keys.state')!), isEmpty);
    expect(jsonDecode(persistent.read('oidc.keys.response.state')!), isEmpty);
    expect(tab.keys, isEmpty);
    expect(await store.getAllKeys(OidcStoreNamespace.state), isEmpty);
    expect(await store.getCurrentNonce(), isNull);
    expect(await store.get(OidcStoreNamespace.secureTokens, key: 'currentToken'), '{}');
  });

  test("clearTransactions in one tab leaves another tab's state and response", () async {
    final otherTabStorage = MemoryKeyValue();
    final otherTab = OidcTransactionStore(persistent: persistent, tab: otherTabStorage);
    await _startSignIn(store);
    await _startSignIn(otherTab, state: 'state-2');
    _redirectHtmlStoresResponse(persistent, _stateId, _response);
    _redirectHtmlStoresResponse(persistent, 'state-2', _response);

    await store.clearTransactions();

    expect(persistent.read('oidc.state.$_stateId'), isNull);
    expect(persistent.read('oidc.response.state.$_stateId'), isNull);
    expect(persistent.read('oidc.state.state-2'), _stateData);
    expect(persistent.read('oidc.response.state.state-2'), _response);
    expect(jsonDecode(persistent.read('oidc.keys.response.state')!), ['state-2']);
    expect(await otherTab.getStatesWithResponses(), hasLength(1));
    expect(await otherTab.getCurrentNonce(), _nonce);
    expect(otherTabStorage.keys, hasLength(2));
  });

  group('hasPendingResponse', () {
    test('is true for a response to a state this tab started', () async {
      await _startSignIn(store);
      _redirectHtmlStoresResponse(persistent, _stateId, _response);

      expect(await store.hasPendingResponse(), isTrue);
    });

    test('is false while the sign-in has no response', () async {
      await _startSignIn(store);

      expect(await store.hasPendingResponse(), isFalse);
    });

    test('is false when nothing was started', () async {
      expect(await store.hasPendingResponse(), isFalse);
    });
  });

  group('hasAbandonedSignIn', () {
    test('a verifier without a response is an abandoned sign-in', () async {
      await _startSignIn(store);

      expect(store.hasAbandonedSignIn(), isTrue);
    });

    test('a verifier with a response is not an abandoned sign-in', () async {
      await _startSignIn(store);
      _redirectHtmlStoresResponse(persistent, _stateId, _response);

      expect(store.hasAbandonedSignIn(), isFalse);
    });

    test('no verifier is not an abandoned sign-in', () async {
      _redirectHtmlStoresResponse(persistent, _stateId, _response);

      expect(store.hasAbandonedSignIn(), isFalse);
    });
  });

  test('refuses the unused session namespace', () {
    expect(() => store.getAllKeys(OidcStoreNamespace.session), throwsUnsupportedError);
    expect(() => store.set(OidcStoreNamespace.session, key: 'k', value: 'v'), throwsUnsupportedError);
  });

  test('refuses a manager id, which would move the keys out of the redirect.html layout', () {
    expect(() => store.getAllKeys(OidcStoreNamespace.state, managerId: 'm'), throwsArgumentError);
    expect(() => store.setMany(OidcStoreNamespace.secureTokens, values: {}, managerId: 'm'), throwsArgumentError);
  });

  test('a response index that is not a JSON array is an error', () {
    persistent.write('oidc.keys.response.state', '{}');

    expect(() => store.getAllKeys(OidcStoreNamespace.stateResponse), throwsFormatException);
  });

  for (final (indexKey, namespace) in [
    ('oidc.keys.response.state', OidcStoreNamespace.stateResponse),
    ('oidc.keys.state', OidcStoreNamespace.state),
  ]) {
    test('a malformed $indexKey names the key and carries no state id', () async {
      persistent.write(indexKey, '["state-secret-1","state-secret-2"');

      final error = await store.getAllKeys(namespace).then<Object?>((_) => null, onError: (Object error) => error);

      expect(error, isA<FormatException>());
      final format = error! as FormatException;
      expect(format.message, contains(indexKey));
      expect(format.source, isNull);
      expect(format.toString(), isNot(contains('state-secret')));
    });
  }

  test('a malformed response index escapes hasPendingResponse without a state id', () async {
    persistent.write('oidc.keys.response.state', '["state-secret-1",');

    final error = await store.hasPendingResponse().then<Object?>((_) => null, onError: (Object error) => error);

    expect(error, isA<FormatException>());
    expect(error.toString(), isNot(contains('state-secret')));
  });

  for (final indexKey in ['oidc.keys.response.state', 'oidc.keys.state']) {
    test(
      'clearTransactions removes a malformed $indexKey, logged without its content, so the next sign-in can start',
      () async {
        final errors = <String>[];
        void record(OutputEvent event) {
          if (event.level == Level.error) errors.addAll(event.lines);
        }

        Logger.addOutputListener(record);
        addTearDown(() => Logger.removeOutputListener(record));
        await _startSignIn(store);
        persistent.write(indexKey, '["state-secret-1",');

        await store.clearTransactions();

        expect(persistent.read(indexKey), isNull);
        expect(persistent.keys.where((key) => !key.startsWith('oidc.keys.')), isEmpty);
        expect(tab.keys, isEmpty);
        expect(errors, contains(allOf(contains('OidcTransactionStore'), contains(indexKey))));
        expect(errors.join('\n'), isNot(contains('state-secret')));

        await _startSignIn(store, state: 'state-2');
        expect(await store.getAllKeys(OidcStoreNamespace.state), {'state-2'});
      },
    );
  }
}
