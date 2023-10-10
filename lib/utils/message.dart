import 'package:flutter/material.dart';

/// Message class for common functions
///
/// ```dart
/// Message.info(context, "Hello World");
///
/// Message.error(context, "Hello World");
///
/// ```
class Message {
  /// Show a message with scaffold messenger
  ///
  /// param [context] is required BuildContext
  /// param [message] is required MessageBody
  /// param [color] is optional messagebox color
  /// param [duration] is optional messagebox duration in seconds
  static void info({required BuildContext context, required String message, Color color = Colors.blue, int duration = 3}) {
    //wrap the message inside a SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: duration),
      ),
    );
  }

  /// Show a error message with scaffold messenger
  ///
  /// param [context] is required BuildContext
  /// param [message] is required MessageBody
  /// param [color] is optional messagebox color
  /// param [duration] is optional messagebox duration in seconds
  static void error({required BuildContext context, required String message, Color color = Colors.red, int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: duration),
      ),
    );
  }
}
