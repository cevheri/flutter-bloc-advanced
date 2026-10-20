import 'package:flutter_bloc_advance/core/security/sensitive_data_scrubber.dart';
import 'package:logger/logger.dart';

enum LogFormat { simple, extended }

/// A simple logger class that wraps the [Logger] class.
///
/// This class provides a simple way to log messages with different log levels.
/// It also provides a way to configure the logger with different options.
///
/// A line is built only for a level that is printed, so the message and the
/// arguments of a dropped level are never turned into text. Email addresses
/// in a printed line are replaced with [emailMask] by [maskEmails], and the
/// secrets that [maskSecrets] finds, such as the value of a `password`
/// member of a JSON body or a `Bearer` token, with [secretMask]. A Map or a
/// List argument has the values of its credential keys masked by
/// [scrubBodyKeys] first.
///
/// Each `{}` in the message takes the text of the next argument, from left
/// to right. The message is scanned once, so an argument whose text contains
/// `{}` is printed as it is and never takes the place of a later one. A `{}`
/// with no argument left is printed as `{}`. An argument with no `{}` left
/// is not printed, and is not turned into text either.
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

  static void configure({required bool isProduction, bool logToFile = false, LogFormat logFormat = LogFormat.simple}) {
    _level = isProduction ? Level.info : Level.debug;
    _logFormat = logFormat;
    final simple = SimplePrinter(printTime: true);
    final pretty = PrettyPrinter(dateTimeFormat: DateTimeFormat.dateAndTime, methodCount: 2);
    LogPrinter printer = _logFormat == LogFormat.simple ? simple : pretty;
    LogOutput output = ConsoleOutput(); // logToFile ? FileOutput(file: File('log.txt'), overrideExisting: true) : ConsoleOutput(); Unsupported operation: Not supported on this platform.
    LogFilter filter = isProduction ? ProductionFilter() : DevelopmentFilter();
    _logger = Logger(filter: filter, printer: printer, output: output, level: _level);
  }

  // generate log methods with message and arguments
  String _msg(dynamic message, [List<dynamic>? args]) {
    final arguments = args ?? const [];
    var next = 0;
    // One pass over the message, so the text of an argument is never searched for "{}".
    final text = "$message".replaceAllMapped(
      "{}",
      (_) => next < arguments.length ? "${_printable(arguments[next++])}" : "{}",
    );
    return maskEmails(maskSecrets("$_name : $text"));
  }

  /// [argument] as it is printed: a Map or a List with the values of its credential keys masked.
  static Object? _printable(Object? argument) =>
      argument is Map || argument is List ? scrubBodyKeys(argument) : argument;

  // The printer calls the closure only after the filter has passed the level, so a dropped level never runs _msg.
  void trace(dynamic message, [List<Object?>? args]) => _logger.t(() => _msg(message, args));

  void debug(dynamic message, [List<Object?>? args]) => _logger.d(() => _msg(message, args));

  void info(dynamic message, [List<Object?>? args]) => _logger.i(() => _msg(message, args));

  void warn(dynamic message, [List<Object?>? args]) => _logger.w(() => _msg(message, args));

  void error(dynamic message, [List<Object?>? args]) => _logger.e(() => _msg(message, args));

  @override
  String toString() {
    return "AppLogger($_name, ${_level.name}, ${_logFormat.name})";
  }
}
