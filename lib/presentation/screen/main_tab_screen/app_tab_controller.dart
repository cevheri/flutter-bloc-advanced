import 'package:flutter/material.dart';
import 'package:get/get.dart';



class AppTabController extends GetxController with GetSingleTickerProviderStateMixin {
  final tabIndex = 0.obs;
  final buildFloatingBar = 0.obs;
  late TabController controller;

  @override
  void onInit() {
    super.onInit();
    controller = TabController(vsync: this, length: 6)
      ..addListener(() {
        buildFloatingBar(controller.index);
        tabIndex(controller.index);
        // tabIndex.value == 0
            // ? MainPageServiceApp().getMainServiceApp()
            // : tabIndex.value == 1
            //     ? BlogPageServiceApp().getBlogServiceApp()
            //     : tabIndex.value == 2
            //         ? ForumPageServiceApp().getForumServiceApp()
            //         : tabIndex.value == 3
            //             ? OtherPageServiceApp().getOtherServiceApp()
            //             : null;
      });
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}
