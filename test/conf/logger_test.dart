import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
