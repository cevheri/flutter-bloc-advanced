import 'package:logger/logger.dart';

enum LogFormat { simple, extended }

/// A simple logger class that wraps the [Logger] class.
///
/// This class provides a simple way to log messages with different log levels.
/// It also provides a way to configure the logger with different options.
///
class AppLogger {
  static late Logger _logger;
  static late Level _level;
  static late LogFormat _logFormat;
  late String _name;

  AppLogger() {
    _name = "Logger";
  }

  AppLogger.getLogger(String name) {
    _name = name;
  }

  static void configure({
    required bool isProduction,
    bool logToFile = false,
    LogFormat logFormat = LogFormat.simple,
  }) {
    _level = isProduction ? Level.info : Level.debug;
    _logFormat = logFormat;
    final simple = SimplePrinter(printTime: true);
    final pretty = PrettyPrinter(
      dateTimeFormat: DateTimeFormat.dateAndTime,
      methodCount: 2,
    );
    LogPrinter printer = _logFormat == LogFormat.simple ? simple : pretty;
    LogOutput output =
        ConsoleOutput(); // logToFile ? FileOutput(file: File('log.txt'), overrideExisting: true) : ConsoleOutput(); Unsupported operation: Not supported on this platform.
    LogFilter filter = isProduction ? ProductionFilter() : DevelopmentFilter();
    _logger = Logger(
      filter: filter,
      printer: printer,
      output: output,
      level: _level,
    );
  }

  // generate log methods with message and arguments
  String _msg(dynamic message, [List<dynamic>? args]) {
    String msg = "$_name : $message";
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        msg = msg.replaceFirst("{}", args[i].toString());
      }
    }
    return msg;
  }

  void trace(dynamic message, [List<Object?>? args]) =>
      _logger.t(_msg(message, args));

  void debug(dynamic message, [List<Object?>? args]) =>
      _logger.d(_msg(message, args));

  void info(dynamic message, [List<Object?>? args]) =>
      _logger.i(_msg(message, args));

  void warn(dynamic message, [List<Object?>? args]) =>
      _logger.w(_msg(message, args));

  void error(dynamic message, [List<Object?>? args]) =>
      _logger.e(_msg(message, args));

  @override
  String toString() {
    return "AppLogger($_name, ${_level.name}, ${_logFormat.name})";
  }
}
