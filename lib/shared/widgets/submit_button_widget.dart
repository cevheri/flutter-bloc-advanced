import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';

class ResponsiveSubmitButton extends StatelessWidget {
  const ResponsiveSubmitButton({
    super.key,
    this.buttonText = 'Save',
    this.onPressed,
    this.isLoading = false,
    this.isWebPlatform,
  });

  final String buttonText;
  final VoidCallback? onPressed;
  final bool isLoading;
  @visibleForTesting
  final bool? isWebPlatform;

  @override
  Widget build(BuildContext context) {
    final submitButton = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: ButtonContent(text: buttonText, isLoading: isLoading),
    );
    if (isWebPlatform ?? kIsWeb) {
      return Align(alignment: Alignment.centerRight, child: submitButton);
    }
    return submitButton;
  }
}

class ButtonContent extends StatelessWidget {
  const ButtonContent({super.key, required this.text, required this.isLoading});

  final String text;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final buttonForegroundColor = Theme.of(context).colorScheme.onPrimary;
    return Row(
      spacing: AppSpacing.sm,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(buttonForegroundColor),
            ),
          ),
        ],
        Text(text),
      ],
    );
  }
}
