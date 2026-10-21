import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  // AppLogger Test
  group("AppLogger Test", () {
    test("Logger Test", () {
      // production
      AppLogger.configure(isProduction: true, logFormat: LogFormat.simple);
      final log = AppLogger();
      log.trace("trace");
      log.debug("debug");
      log.info("info");
      log.warn("warn");
      log.error("error");
      expect(log.toString(), "AppLogger(Logger, info, simple)");
    });

    test("Logger test with name", () {
      // production
      AppLogger.configure(isProduction: true, logFormat: LogFormat.simple);
      final log = AppLogger.getLogger("logger_test.dart");
      log.trace("trace");
      log.debug("debug");
      log.info("info");
      log.warn("warn");
      log.error("error");
      expect(log.toString(), "AppLogger(logger_test.dart, info, simple)");
    });

    test("Logger Test with parameters", () {
      // production
      AppLogger.configure(isProduction: true, logFormat: LogFormat.simple);
      final log = AppLogger.getLogger("logger_test.dart");
      log.trace("trace p1:{}", ["param1"]);
      log.debug("debug");
      log.info("info");
      log.warn("warn");
      log.error("error");
      expect(log.toString(), "AppLogger(logger_test.dart, info, simple)");
    });

    test("Logger Test with parameters dev env", () {
      // production
      AppLogger.configure(isProduction: false, logFormat: LogFormat.extended);
      final log = AppLogger.getLogger("logger_test.dart");
      log.trace("trace p1:{}", ["param1"]);
      log.debug("debug");
      log.info("info");
      log.warn("warn");
      log.error("error");
      expect(log.toString(), "AppLogger(logger_test.dart, debug, extended)");
    });
  });

  // Regression: a line that carried an email, such as a request path with a login in it, was printed as it was, so
  // the address reached the console, and on web with a Sentry DSN the breadcrumbs made from it.
  group('AppLogger email masking', () {
    for (final format in LogFormat.values) {
      test('masks an email in the message (${format.name})', () {
        AppLogger.configure(isProduction: false, logFormat: format);
        final lines = _capturePrintedLines();

        AppLogger.getLogger('MaskTest').info('signed in as jane.doe@example.com');

        expect(lines, anyElement(contains('MaskTest : signed in as [REDACTED_EMAIL]')));
        expect(lines, everyElement(isNot(contains('jane.doe'))));
      });

      test('masks an email in an argument (${format.name})', () {
        AppLogger.configure(isProduction: false, logFormat: format);
        final lines = _capturePrintedLines();

        AppLogger.getLogger('MaskTest').warn('GET {} failed: {}', ['/admin/users/jane.doe@example.com', 'timeout']);

        expect(lines, anyElement(contains('MaskTest : GET /admin/users/[REDACTED_EMAIL] failed: timeout')));
        expect(lines, everyElement(isNot(contains('jane.doe'))));
      });
    }
  });

  // Regression: AppLogger masked only emails, so a line that carried a credential in a known shape printed it: a JSON
  // body with a token member, a Map of form values, an Authorization header or a URL with a token in its query. The
  // console of the build keeps every line of a level it prints.
  group('AppLogger credential masking', () {
    setUp(() => AppLogger.configure(isProduction: false, logFormat: LogFormat.simple));

    test('masks the value of a credential member of a JSON argument', () {
      final lines = _capturePrintedLines();

      AppLogger.getLogger('MaskTest')
          .error('Invalid Request: {}', ['{"status":400,"refresh_token":"rt-9f8e7d6c","detail":"expired"}']);

      expect(
        lines,
        anyElement(
          contains('MaskTest : Invalid Request: {"status":400,"refresh_token":"[REDACTED]","detail":"expired"}'),
        ),
      );
    });

    test('masks the value of a credential key of a Map argument', () {
      final lines = _capturePrintedLines();

      AppLogger.getLogger('MaskTest').info('params: {}', [
        {'login': 'admin', 'newPassword': 'Adm1nSet!Pw'},
      ]);

      expect(lines, anyElement(contains('MaskTest : params: {login: admin, newPassword: [REDACTED]}')));
    });

    test('masks a bearer token and a token in a query string', () {
      final lines = _capturePrintedLines();

      AppLogger.getLogger('MaskTest').warn('{} -> {}', [
        'Authorization: Bearer at-opaque-0a1b2c3d',
        '/callback?state=1&access_token=at-opaque-0a1b2c3d',
      ]);

      expect(
        lines,
        anyElement(
          contains('MaskTest : Authorization: Bearer [REDACTED] -> /callback?state=[REDACTED]&access_token=[REDACTED]'),
        ),
      );
    });

    // Guards against over-masking: a masked token preview and a line without a credential print as they are.
    test('keeps a line without a credential in a known shape as it is', () {
      final lines = _capturePrintedLines();

      AppLogger.getLogger('MaskTest')
          .debug('Request [{}] {} (auth: {}, token: {})', ['GET', '/account?page=0&size=20', true, 'eyJh…VyZQ']);

      expect(
        lines,
        anyElement(endsWith('MaskTest : Request [GET] /account?page=0&size=20 (auth: true, token: eyJh…VyZQ)')),
      );
    });
  });

  // Regression: each argument replaced the first "{}" left in the line built so far, so an argument whose text
  // contained "{}", such as a name typed into the user search or an empty map, took the next argument's place.
  group('AppLogger placeholders', () {
    test('prints an argument that contains {} as it is', () {
      AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
      final lines = _capturePrintedLines();

      AppLogger.getLogger('PlaceholderTest').info('event: {} params: {}', ['{}', 'x']);

      expect(lines, anyElement(contains('PlaceholderTest : event: {} params: x')));
    });

    // Guards the SLF4J behavior the one-pass rewrite keeps: a "{}" with no argument left stays in the line as it is.
    test('keeps a {} that has no argument left', () {
      AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
      final lines = _capturePrintedLines();

      AppLogger.getLogger('PlaceholderTest').info('page: {}, size: {}, name: {}', [0, 10]);

      expect(lines, anyElement(contains('PlaceholderTest : page: 0, size: 10, name: {}')));
    });

    test('neither prints nor turns into text an argument that has no {} left', () {
      AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
      final lines = _capturePrintedLines();
      final unused = _FakeLogArgument();

      AppLogger.getLogger('PlaceholderTest').info('GET {}', ['/admin/users', unused]);

      expect(lines, anyElement(endsWith('PlaceholderTest : GET /admin/users')));
      expect(unused.toStringCalls, 0);
    });
  });

  // Regression: the line was built before the logger's filter ran, so the arguments of a dropped level were still
  // turned into text.
  group('AppLogger lazy message', () {
    test('does not call toString on an argument of a level the filter drops', () {
      AppLogger.configure(isProduction: true, logFormat: LogFormat.simple);
      final argument = _FakeLogArgument();

      AppLogger.getLogger('LazyTest').debug('state: {}', [argument]);

      expect(argument.toStringCalls, 0);
    });

    test('does not call a closure argument of a level the filter drops', () {
      AppLogger.configure(isProduction: true, logFormat: LogFormat.simple);
      var calls = 0;

      AppLogger.getLogger('LazyTest').debug('trace: {}', [
        () {
          calls++;
          return 'built';
        },
      ]);

      expect(calls, 0);
    });

    test('prints what a closure argument returns, with the credential keys of a Map masked', () {
      AppLogger.configure(isProduction: false, logFormat: LogFormat.simple);
      final lines = _capturePrintedLines();

      AppLogger.getLogger('LazyTest').info('head: {} params: {}', [
        () => 'line 1',
        () => {'login': 'admin', 'password': 'Adm1nSet!Pw'},
      ]);

      expect(lines, anyElement(endsWith('LazyTest : head: line 1 params: {login: admin, password: [REDACTED]}')));
    });
  });
}

/// Collects every line the loggers print until the test ends.
List<String> _capturePrintedLines() {
  final lines = <String>[];
  void collect(OutputEvent event) => lines.addAll(event.lines);

  Logger.addOutputListener(collect);
  addTearDown(() => Logger.removeOutputListener(collect));
  return lines;
}

/// A log argument that counts how often it is turned into text.
class _FakeLogArgument {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls++;
    return 'fake argument';
  }
}
