import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Message {




  static Future getMessage({required BuildContext context, required String title,required String content}) async {
    Get.snackbar(
      title,
      content,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(100, 20, 100, 20),
      isDismissible: true,
    );
  }

  //errorMessage
  static Future errorMessage({required BuildContext context, required String title,required String content}) async {
    Get.snackbar(
      title,

      content,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(100, 20, 100, 20),
      isDismissible: true,
      colorText: Colors.red,
    );
  }

  static Future calculated({
    required BuildContext context,
    required String title,
    required String message,
    required int duration,
    Color color = Colors.blueGrey,
  }) async {
    Get.snackbar(
      title,
      message,
      animationDuration: const Duration(milliseconds: 500),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.primary,
      borderRadius: 10,
      margin: const EdgeInsets.fromLTRB(100, 10, 100, 350),
      colorText: Colors.white,
      duration: Duration(seconds: duration),
      isDismissible: false,
      forwardAnimationCurve: Curves.easeOutBack,
      overlayBlur: 1.5,
    );
  }
}
