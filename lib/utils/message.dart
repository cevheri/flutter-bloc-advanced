import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Message {
  static const _duration = Duration(seconds: 3);

  static Future getMessage({
    required BuildContext context,
    required String title,
    required String content,
    Duration duration = Message._duration,
  }) async {
    Get.snackbar(
      title,
      content,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(100, 20, 100, 20),
      isDismissible: true,
      duration: duration,
    );
  }

  static Future errorMessage({
    required BuildContext context,
    required String title,
    required String content,
    Duration duration = Message._duration,
  }) async {
    Get.snackbar(
      title,
      content,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(100, 20, 100, 20),
      isDismissible: true,
      colorText: Colors.red,
      duration: duration,
    );
  }
}
