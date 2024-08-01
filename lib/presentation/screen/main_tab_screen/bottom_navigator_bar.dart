import 'package:custom_navigation_bar/custom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:string_2_icon/string_2_icon.dart';

import '../../../generated/l10n.dart';
import 'app_tab_controller.dart';

class BuildFloatingBarState extends StatefulWidget {
  const BuildFloatingBarState({super.key});

  @override
  State<BuildFloatingBarState> createState() => _BuildFloatingBarStateState();
}

class _BuildFloatingBarStateState extends State<BuildFloatingBarState> {
  final AppTabController tabx = Get.put(AppTabController());

  @override
  Widget build(BuildContext context) {
    final getXController = Get.put(AppTabController());
    return Obx(
      () => Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: CustomNavigationBar(
          selectedColor: Color(0xff625aff),
          scaleFactor: 0.1,
          iconSize: 25.0,
          blurEffect: false,
          scaleCurve: Curves.easeOutQuad,
          bubbleCurve: Curves.easeOutQuad,
          elevation: 0,
          strokeColor: Colors.transparent,
          backgroundColor: Colors.grey,
          borderRadius: const Radius.circular(0.0),
          items: [
            CustomNavigationBarItem(
              title: Text(S.of(context).home, style: TextStyle(fontSize: 7, color: Colors.black54)),
              selectedTitle: Text(S.of(context).home, style: TextStyle(fontSize: 9, color: Colors.red)),
              icon: Icon(String2Icon.getIconDataFromString("mdi-home-outline")),
              selectedIcon: Icon(String2Icon.getIconDataFromString("mdi-home-outline"), color: Colors.red),
            ),
            CustomNavigationBarItem(
              title: Text(S.of(context).services, style: TextStyle(fontSize: 7, color: Colors.black54)),
              selectedTitle: Text(S.of(context).services, style: TextStyle(fontSize: 9, color: Colors.red)),
              icon: Icon(String2Icon.getIconDataFromString("mdi-format-align-bottom")),
              selectedIcon: Icon(String2Icon.getIconDataFromString("mdi-format-align-bottom"), color: Colors.red),
            ),
            CustomNavigationBarItem(
              title: Text(S.of(context).products, style: TextStyle(fontSize: 7, color: Colors.black54)),
              selectedTitle: Text(S.of(context).products, style: TextStyle(fontSize: 9, color: Colors.red)),
              icon: Icon(String2Icon.getIconDataFromString("mdi-package-variant-closed")),
              selectedIcon: Icon(String2Icon.getIconDataFromString("mdi-package-variant-closed"), color: Colors.red),
              //mdi-format-align-bottom
            ),
            CustomNavigationBarItem(
              title: Text(S.of(context).about_us, style: TextStyle(fontSize: 7, color: Colors.black54)),
              selectedTitle: Text(S.of(context).about_us, style: TextStyle(fontSize: 9, color: Colors.red)),
              icon: Icon(String2Icon.getIconDataFromString("mdi-information")),
              selectedIcon: Icon(String2Icon.getIconDataFromString("mdi-information"), color: Colors.red),
            ),
            CustomNavigationBarItem(
              title: Text(S.of(context).our_references, style: TextStyle(fontSize: 7, color: Colors.black54)),
              selectedTitle: Text(S.of(context).our_references, style: TextStyle(fontSize: 9, color: Colors.red)),
              icon: Icon(String2Icon.getIconDataFromString("mdi-account-group")),
              selectedIcon: Icon(String2Icon.getIconDataFromString("mdi-account-group"), color: Colors.red),
            ),
            CustomNavigationBarItem(
              title: Text(S.of(context).faq, style: TextStyle(fontSize: 7, color: Colors.black54)),
              selectedTitle: Text(S.of(context).faq, style: TextStyle(fontSize: 9, color: Colors.red)),
              icon: Image.asset("assets/images/img.png", color: Colors.black54),
              selectedIcon: Image.asset("assets/images/img.png", color: Colors.red),
            ),
          ],
          onTap: (index) {
            setState(() {
              tabx.controller.index = index;
            });
          },
          currentIndex: getXController.buildFloatingBar.value,
          isFloating: false,
        ),
      ),
    );
  }
}
