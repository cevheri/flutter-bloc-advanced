import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Message {
  static Future getMessage(
      {required BuildContext context,
      required String title,
      required String content}) async {
    Get.snackbar(
      title,
      content,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(100, 20, 100, 20),
      isDismissible: true,
    );
  }


  static Future errorMessage(
      {required BuildContext context,
      required String title,
      required String content}) async {
    Get.snackbar(
      title,
      content,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(100, 20, 100, 20),
      isDismissible: true,
      colorText: Colors.red,
    );
  }


}
