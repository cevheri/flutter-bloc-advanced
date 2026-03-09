import 'package:flutter/material.dart';

class Message {
  static const _duration = Duration(seconds: 3);

  static Future getMessage({
    required BuildContext context,
    required String title,
    required String content,
    Duration duration = Message._duration,
  }) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(content), duration: duration, behavior: SnackBarBehavior.floating));
  }

  static Future errorMessage({
    required BuildContext context,
    required String title,
    required String content,
    Duration duration = Message._duration,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(content, style: TextStyle(color: Theme.of(context).colorScheme.onError)),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
