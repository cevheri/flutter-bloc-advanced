import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// App stateless widget
/// This class is used to create a stateless widget that can be used in the app.
/// This widget is used to create a multi-platform widget that can be used in Android, iOS, and Web.
///
/// Example:
/// ```dart
/// class PlatformButton extends PlatformWidget {
///   final String text;
///   final VoidCallback onPressed;
///   final bool isLoading;
///
///   const PlatformButton({
///     super.key,
///     required this.text,
///     required this.onPressed,
///     this.isLoading = false,
///   });
///
///   @override
///   Widget buildCupertinoWidget(BuildContext context) {
///     return CupertinoButton(
///       onPressed: isLoading ? null : onPressed,
///       child: isLoading
///         ? const CupertinoActivityIndicator()
///         : Text(text),
///     );
///   }
///
///   @override
///   Widget buildMaterialWidget(BuildContext context) {
///     return ElevatedButton(
///       onPressed: isLoading ? null : onPressed,
///       child: isLoading
///         ? const CircularProgressIndicator()
///         : Text(text),
///     );
///   }
///
///   @override
///   Widget buildWebWidget(BuildContext context) {
///     // Custom web widgets
///     return buildMaterialWidget(context);
///   }
/// }
abstract class AppStatelessWidget extends StatelessWidget {
  const AppStatelessWidget({super.key});

  Widget buildCupertinoWidget(BuildContext context);

  Widget buildMaterialWidget(BuildContext context);

  Widget buildWebWidget(BuildContext context);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return buildWebWidget(context);
    }
    if (Platform.isIOS) {
      return buildCupertinoWidget(context);
    }
    return buildMaterialWidget(context);
  }
}
