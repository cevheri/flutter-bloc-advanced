import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/configuration/padding_spacing.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class ResponsiveFormBuilder extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool autovalidateMode;
  final VoidCallback? onChanged;
  final bool shrinkWrap;   

  const ResponsiveFormBuilder({
    super.key,
    required this.formKey,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.autovalidateMode = false,
    this.onChanged,
    this.shrinkWrap = false, 
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      autovalidateMode: autovalidateMode ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      onChanged: onChanged,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Spacing.formMaxWidthLarge),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.medium),
              child: Column(
                spacing: Spacing.medium,
                mainAxisAlignment: mainAxisAlignment,
                crossAxisAlignment: crossAxisAlignment,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
