import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_analytics_service.dart';
import 'package:flutter_bloc_advance/infrastructure/analytics/sentry_scrub.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

SentryEvent _eventWithHeaders(Map<String, String> headers) => SentryEvent(request: SentryRequest(headers: headers));

SentryEvent _eventWithBody(Object? body) => SentryEvent(request: SentryRequest(data: body));

SentryEvent _eventWithMessage(String message) => SentryEvent(message: SentryMessage(message));

SentryEvent _eventWithExceptionValue(String value) {
  return SentryEvent(
    exceptions: [SentryException(type: 'TestException', value: value)],
  );
}

void main() {
  group('sentryBeforeSend — header scrubbing', () {
    test('removes Authorization header (case-insensitive)', () {
      final result = sentryBeforeSend(
        _eventWithHeaders({'Authorization': 'Bearer token', 'Accept': 'application/json'}),
      );
      expect(result.request?.headers.containsKey('Authorization'), isFalse);
      expect(result.request?.headers['Accept'], 'application/json');
    });

    test('removes lowercase authorization', () {
      final result = sentryBeforeSend(_eventWithHeaders({'authorization': 'Bearer x', 'X-Other': 'y'}));
      expect(result.request?.headers.containsKey('authorization'), isFalse);
      expect(result.request?.headers['X-Other'], 'y');
    });

    test('removes Cookie and Set-Cookie headers', () {
      final result = sentryBeforeSend(_eventWithHeaders({'Cookie': 'sid=abc', 'Set-Cookie': 'sid=abc', 'X-K': 'v'}));
      expect(result.request?.headers.containsKey('Cookie'), isFalse);
      expect(result.request?.headers.containsKey('Set-Cookie'), isFalse);
      expect(result.request?.headers['X-K'], 'v');
    });
  });

  // Regression: only the Authorization, Cookie and Set-Cookie headers were dropped by name, and every other header
  // value and every env value reached Sentry as it was, so a JWT or an email in a custom header or in the env did too.
  group('sentryBeforeSend', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';

    test('masks emails and JWTs in header values', () {
      final result = sentryBeforeSend(
        _eventWithHeaders({'X-Debug-Context': 'session $jwt', 'X-User-Email': 'jane.doe@example.com'}),
      );
      expect(result.request?.headers, {
        'X-Debug-Context': 'session [REDACTED_JWT]',
        'X-User-Email': '[REDACTED_EMAIL]',
      });
    });

    test('masks emails and JWTs in env values', () {
      final result = sentryBeforeSend(
        SentryEvent(
          request: SentryRequest(
            env: {'REMOTE_USER': 'jane.doe@example.com', 'SESSION': jwt, 'QUERY_STRING': 'code=4f2a9c&state=st4te999'},
          ),
        ),
      );
      expect(result.request?.env, {
        'REMOTE_USER': '[REDACTED_EMAIL]',
        'SESSION': '[REDACTED_JWT]',
        'QUERY_STRING': 'code=[REDACTED]&state=[REDACTED]',
      });
    });

    test('keeps a header value without a secret as it was', () {
      final result = sentryBeforeSend(_eventWithHeaders({'Accept': 'application/json', 'X-Request-Id': 'abc-123'}));
      expect(result.request?.headers, {'Accept': 'application/json', 'X-Request-Id': 'abc-123'});
    });

    // An opaque token has no JWT shape and names no key inside its value, so only the name of its header says what it
    // is.
    test('masks the whole value of a header named like a credential', () {
      final result = sentryBeforeSend(
        _eventWithHeaders({'X-Auth-Token': 'at-opaque-0a1b2c3d', 'Accept': 'text/plain'}),
      );
      expect(result.request?.headers, {'X-Auth-Token': '[REDACTED]', 'Accept': 'text/plain'});
    });
  });

  group('sentryBeforeSend — body scrubbing (Map shape)', () {
    test('masks the values of password, otp, token, refreshToken keys', () {
      final body = {
        'username': 'alice',
        'password': 'p@ss',
        'otp': '123456',
        'token': 'xxx',
        'refreshToken': 'yyy',
        'note': 'kept',
      };
      final result = sentryBeforeSend(_eventWithBody(body));
      expect(result.request!.data, {
        'username': 'alice',
        'password': '[REDACTED]',
        'otp': '[REDACTED]',
        'token': '[REDACTED]',
        'refreshToken': '[REDACTED]',
        'note': 'kept',
      });
    });

    test('key match is case-insensitive', () {
      final body = {'Password': 'a', 'OTP': 'b', 'newPassword': 'c'};
      final result = sentryBeforeSend(_eventWithBody(body));
      expect(result.request!.data, {'Password': '[REDACTED]', 'OTP': '[REDACTED]', 'newPassword': '[REDACTED]'});
    });

    test('keeps a non-Map body without an email or a JWT as it is', () {
      final result = sentryBeforeSend(_eventWithBody('plain string body'));
      expect(result.request?.data, 'plain string body');
    });
  });

  group('sentryBeforeSend — JWT masking', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';

    test('masks a JWT-shaped token inside an exception value', () {
      final result = sentryBeforeSend(_eventWithExceptionValue('Failed with token=$jwt — try again'));
      final value = result.exceptions?.first.value ?? '';
      expect(value.contains(jwt), isFalse, reason: 'raw JWT must not appear');
      expect(value.contains('[REDACTED_JWT]'), isTrue);
    });

    test('masks JWT in event.message', () {
      final result = sentryBeforeSend(_eventWithMessage('Token rotated: $jwt'));
      final formatted = result.message?.formatted ?? '';
      expect(formatted.contains(jwt), isFalse);
      expect(formatted.contains('[REDACTED_JWT]'), isTrue);
    });

    test('leaves an exception value without a JWT or an email untouched', () {
      final result = sentryBeforeSend(_eventWithExceptionValue('Server returned 500 with body {"error":"oops"}'));
      expect(result.exceptions?.first.value, 'Server returned 500 with body {"error":"oops"}');
    });

    test('masks a JWT in the request query string and fragment', () {
      final result = sentryBeforeSend(
        SentryEvent(
          request: SentryRequest(url: 'https://app.example/', queryString: 'token=$jwt', fragment: 'access_token=$jwt'),
        ),
      );
      expect(result.request?.queryString, 'token=[REDACTED_JWT]');
      expect(result.request?.fragment, 'access_token=[REDACTED_JWT]');
    });
  });

  // On web the SDK attaches the page location to every error: it splits window.location into url, query string and
  // fragment, and names the event after the path. go_router keeps the location in the fragment under the default hash
  // URL strategy and in the path under the path strategy, so `/login-otp-verify/:email` exposes the user's email.
  group('sentryBeforeSend - page location', () {
    test('redacts an email in the fragment (hash URL strategy)', () {
      final result = sentryBeforeSend(
        SentryEvent(
          request: SentryRequest(url: 'https://app.example/', fragment: '/login-otp-verify/jane.doe@example.com'),
        ),
      );
      expect(result.toJson().toString(), isNot(contains('jane.doe')));
      expect(result.request?.fragment, '/login-otp-verify/[REDACTED_EMAIL]');
    });

    test('redacts an email in the url, query string and transaction (path URL strategy)', () {
      final result = sentryBeforeSend(
        SentryEvent(
          transaction: '/login-otp-verify/jane.doe@example.com',
          request: SentryRequest(
            url: 'https://app.example/login-otp-verify/jane.doe@example.com',
            queryString: 'email=jane.doe%40example.com',
          ),
        ),
      );
      expect(result.toJson().toString(), isNot(contains('jane.doe')));
      expect(result.request?.url, 'https://app.example/login-otp-verify/[REDACTED_EMAIL]');
      expect(result.request?.queryString, 'email=[REDACTED_EMAIL]');
      expect(result.transaction, '/login-otp-verify/[REDACTED_EMAIL]');
    });
  });

  group('sentryBeforeSend — passthroughs', () {
    test('event with no request or exception passes through unchanged', () {
      final event = SentryEvent(message: SentryMessage('Plain note'));
      final result = sentryBeforeSend(event);
      expect(result.message?.formatted, 'Plain note');
    });
  });

  // Regression: the exception values were masked for JWTs only, so an email in one reached Sentry. ApiClient puts the
  // error response body into the exception it throws, and a Spring error body names the request path, such as
  // /api/admin/users/{login}, where the login is the email the user registered with. The message was masked for JWTs
  // only too and the request body only lost its secret keys, but nothing in the app fills either. A fork can fill the
  // message through Sentry.captureMessage and the body through an HTTP integration such as sentry_dio.
  group('sentryBeforeSend - emails', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';

    test('masks an email in an exception value', () {
      final result = sentryBeforeSend(
        _eventWithExceptionValue('Not found: {"status":404,"path":"/api/admin/users/jane.doe@example.com"}'),
      );
      expect(result.exceptions?.first.value, 'Not found: {"status":404,"path":"/api/admin/users/[REDACTED_EMAIL]"}');
    });

    test('masks an email in the formatted message, the template and the params', () {
      final result = sentryBeforeSend(
        SentryEvent(
          message: SentryMessage(
            'Signed in as jane.doe@example.com',
            template: 'Signed in as %s (was jane.doe@example.com)',
            params: ['jane.doe@example.com', 3],
          ),
        ),
      );
      expect(result.message?.formatted, 'Signed in as [REDACTED_EMAIL]');
      expect(result.message?.template, 'Signed in as %s (was [REDACTED_EMAIL])');
      expect(result.message?.params, ['[REDACTED_EMAIL]', 3]);
    });

    test('masks emails and JWTs in the values of a Map body, at any depth', () {
      final result = sentryBeforeSend(
        _eventWithBody({
          'login': 'jane.doe@example.com',
          'password': 'p@ss',
          'profile': {
            'emails': ['jane.doe@example.com', 'j.doe@example.org'],
            'note': 'session $jwt',
          },
          'age': 42,
        }),
      );
      expect(result.request?.data, {
        'login': '[REDACTED_EMAIL]',
        'password': '[REDACTED]',
        'profile': {
          'emails': ['[REDACTED_EMAIL]', '[REDACTED_EMAIL]'],
          'note': 'session [REDACTED_JWT]',
        },
        'age': 42,
      });
    });

    test('masks an email and a JWT in a raw string body', () {
      final result = sentryBeforeSend(_eventWithBody('{"email":"jane.doe@example.com","id_token":"$jwt"}'));
      expect(result.request?.data, '{"email":"[REDACTED_EMAIL]","id_token":"[REDACTED_JWT]"}');
    });
  });

  // Regression: the text of an event and of a breadcrumb was masked for emails and JWTs only, so a credential member of
  // a JSON body, a bearer token that is not a JWT, or a credential key of the data of a breadcrumb, such as the
  // parameters of an analytics event, reached Sentry.
  group('sentry scrubbers - credentials', () {
    test('masks a credential member and a bearer token in an exception value and the message', () {
      final result = sentryBeforeSend(
        SentryEvent(
          message: SentryMessage('retry with Bearer at-opaque-0a1b2c3d'),
          exceptions: [
            SentryException(
              type: 'FormatException',
              value: 'Unexpected end: {"id_token":"at-opaque-0a1b2c3d","refresh_token":"rt-9f8e7d6c"',
            ),
          ],
        ),
      );

      expect(result.message?.formatted, 'retry with Bearer [REDACTED]');
      expect(result.exceptions?.first.value, 'Unexpected end: {"id_token":"[REDACTED]","refresh_token":"[REDACTED]"');
    });

    test('masks the value of a credential key in the data of a breadcrumb, at any depth', () {
      final result = sentryBeforeBreadcrumb(
        Breadcrumb(
          category: 'event',
          message: 'pin_reset',
          data: {
            'step': 2,
            'otp': '493817',
            'form': {'login': 'admin', 'newPassword': 'Adm1nSet!Pw'},
          },
        ),
      );

      expect(result?.data, {
        'step': 2,
        'otp': '[REDACTED]',
        'form': {'login': 'admin', 'newPassword': '[REDACTED]'},
      });
    });
  });

  // Regression: no beforeBreadcrumb was installed, so a breadcrumb that did not come from AppLogger output reached
  // Sentry as it was: the breadcrumbs of SentryAnalyticsService, the navigation breadcrumbs, debugPrint lines, which on
  // web include the text of an uncaught error, and on web every other printed line. The http and ui breadcrumbs below
  // stand for the ones a fork adds through sentry_dio or SentryUserInteractionWidget.
  group('sentryBeforeBreadcrumb', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';

    test('masks an email and a JWT in the url and the query of an http breadcrumb', () {
      final result = sentryBeforeBreadcrumb(
        Breadcrumb.http(
          url: Uri.parse('https://api.example.test/admin/users/jane.doe@example.com'),
          method: 'GET',
          statusCode: 503,
          httpQuery: 'access_token=$jwt',
        ),
      );
      expect(result?.data, {
        'url': 'https://api.example.test/admin/users/[REDACTED_EMAIL]',
        'method': 'GET',
        'status_code': 503,
        'http.query': 'access_token=[REDACTED_JWT]',
      });
    });

    test('masks an email and a JWT in the message of a console breadcrumb', () {
      final result = sentryBeforeBreadcrumb(
        Breadcrumb.console(message: 'GET /admin/users/jane.doe@example.com Authorization: Bearer $jwt'),
      );
      expect(result?.message, 'GET /admin/users/[REDACTED_EMAIL] Authorization: Bearer [REDACTED_JWT]');
    });

    test('masks an email in the route arguments of a navigation breadcrumb and keeps them a map', () {
      final result = sentryBeforeBreadcrumb(
        RouteObserverBreadcrumb(
          navigationType: 'didPush',
          from: const RouteSettings(name: 'login-otp'),
          to: const RouteSettings(name: 'login-otp-verify', arguments: {'email': 'jane.doe@example.com'}),
        ),
      );
      expect(result?.data, {
        'state': 'didPush',
        'from': 'login-otp',
        'to': 'login-otp-verify',
        'to_arguments': {'email': '[REDACTED_EMAIL]'},
      });
      // Before handing a breadcrumb to the native SDK, Sentry turns a nested map into its toString unless it is a
      // Map<String, dynamic>.
      expect(result?.data?['to_arguments'], isA<Map<String, dynamic>>());
    });

    // The key state also carries the OIDC state, so only the navigator event names that RouteObserverBreadcrumb writes
    // under it are kept, and only in a navigation breadcrumb.
    test('masks the state of a navigation breadcrumb that is not a navigator event name', () {
      final result = sentryBeforeBreadcrumb(
        Breadcrumb(category: 'navigation', type: 'navigation', data: {'state': 'st4te999', 'to': 'callback'}),
      );
      expect(result?.data, {'state': '[REDACTED]', 'to': 'callback'});
    });

    test('masks a navigator event name under state in a breadcrumb that is not a navigation one', () {
      final result = sentryBeforeBreadcrumb(Breadcrumb(category: 'event', data: {'state': 'didPop'}));
      expect(result?.data, {'state': '[REDACTED]'});
    });

    test('masks an email in the message and the data of a ui breadcrumb', () {
      final result = sentryBeforeBreadcrumb(
        Breadcrumb.userInteraction(
          subCategory: 'click',
          message: 'jane.doe@example.com',
          viewId: 'user_row',
          data: {'label': 'Edit jane.doe@example.com'},
        ),
      );
      expect(result?.message, '[REDACTED_EMAIL]');
      expect(result?.data, {'view.id': 'user_row', 'label': 'Edit [REDACTED_EMAIL]'});
    });

    // Guards against the hook dropping or reshaping data: a breadcrumb with nothing to mask reaches Sentry as it was.
    test('keeps a breadcrumb without an email or a JWT as it was', () {
      final breadcrumb = Breadcrumb(
        category: 'event',
        message: 'bloc_transition',
        data: {
          'bloc': 'UserListBloc',
          'count': 3,
          'loaded': true,
          'pages': [1, 2],
          'filter': {'authority': 'ROLE_USER'},
        },
      );
      final before = jsonEncode(breadcrumb.toJson());

      final result = sentryBeforeBreadcrumb(breadcrumb);

      expect(jsonEncode(result?.toJson()), before);
    });
  });

  // The hooks AppBootstrap installs, through installSentryScrubbers and the real SDK: the breadcrumbs of an error event
  // come from the scope, where the beforeBreadcrumb hook ran when each was added, and beforeSend scrubs the rest of the
  // event.
  group('Sentry SDK with installSentryScrubbers', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhYmMifQ.signaturepart';
    late List<String> sentEvents;

    setUp(() async {
      sentEvents = [];
      await Sentry.init((options) {
        options.dsn = 'https://public@example.invalid/1';
        options.transport = _CapturingTransport(sentEvents);
        installSentryScrubbers(options);
      });
      addTearDown(Sentry.close);
    });

    test('sends an error event without the email or the JWT, in the event or in its breadcrumbs', () async {
      SentryAnalyticsService().logUserAction(action: 'open_user', target: 'jane.doe@example.com');
      await Sentry.addBreadcrumb(
        Breadcrumb.http(url: Uri.parse('https://api.example.test/admin/users/jane.doe@example.com'), method: 'GET'),
      );
      await Sentry.addBreadcrumb(Breadcrumb.console(message: 'Authorization: Bearer $jwt'));

      // What ApiClient throws for a 404 whose body names the request path.
      await Sentry.captureException(FetchDataException('Not found: {"path":"/api/admin/users/jane.doe@example.com"}'));

      final sent = sentEvents.single;
      expect(sent, isNot(contains('jane.doe')));
      expect(sent, isNot(contains(jwt)));
      expect(sent, contains('"data":{"target":"[REDACTED_EMAIL]"}'));
      expect(sent, contains('"url":"https://api.example.test/admin/users/[REDACTED_EMAIL]"'));
      expect(sent, contains('"message":"Authorization: Bearer [REDACTED_JWT]"'));
      expect(
        sent,
        contains(r'"value":"Error During Communication: Not found: {\"path\":\"/api/admin/users/[REDACTED_EMAIL]\"}"'),
      );
    });

    test('sends an event without the JWT in a custom request header', () async {
      await Sentry.captureEvent(
        SentryEvent(
          message: SentryMessage('request failed'),
          request: SentryRequest(url: 'https://api.example.test/', headers: {'X-Debug-Context': jwt}),
        ),
      );

      final sent = sentEvents.single;
      expect(sent, isNot(contains(jwt)));
      expect(sent, contains('"X-Debug-Context":"[REDACTED_JWT]"'));
    });
  });

  // Regression: on web SentryFlutter.init runs the app in the zone of sentryRunZonedGuarded, whose print hook turned
  // every printed line into a console breadcrumb, and AppLogger prints each line it logs. beforeBreadcrumb masks only
  // emails and JWTs, so a password or a code that an error line carried went out with the next error event.
  // Sentry.init with an appRunner takes the same zone.
  test('sends no line the app prints as a breadcrumb when the app runs in the Sentry zone', () async {
    AppLogger.configure(isProduction: true);
    addTearDown(() => AppLogger.configure(isProduction: false));
    final sentEvents = <String>[];
    final done = Completer<void>();

    await Sentry.init(
      (options) {
        options.dsn = 'https://public@example.invalid/1';
        options.transport = _CapturingTransport(sentEvents);
        installSentryScrubbers(options);
      },
      appRunner: () async {
        AppLogger.getLogger('BusinessException').error('Invalid Request: {}', [
          '{"errors":[{"field":"newPassword","rejectedValue":"NewPass#2"}],"detail":"OTP 493817"}',
        ]);
        await Sentry.captureException(StateError('a later error'));
        done.complete();
      },
    );
    addTearDown(Sentry.close);
    await done.future;

    final sent = sentEvents.single;
    expect(sent, contains('a later error'));
    expect(sent, allOf(isNot(contains('NewPass#2')), isNot(contains('493817')), isNot(contains('Invalid Request'))));
  });
}

/// Keeps the JSON of every event the SDK sends, as it would go over the wire, and sends nothing.
class _CapturingTransport implements Transport {
  _CapturingTransport(this._sentEvents);

  final List<String> _sentEvents;

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    for (final item in envelope.items) {
      if (item.originalObject is SentryEvent) _sentEvents.add(utf8.decode(await item.dataFactory()));
    }
    return SentryId.newId();
  }
}
