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
