import 'package:flutter/material.dart';


class WebViewScreen extends StatelessWidget {
  WebViewScreen({super.key, required this.content});

  final String content;

  final GlobalKey webViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: content,
              style: TextStyle(
                color: Colors.black,
                decoration: TextDecoration.none,
                height: 1.5,
                fontSize: 20,
              ),
            ),
          ),

      ),
    );
  }
}
