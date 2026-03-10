import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// Input variant.
enum AppInputVariant { standard, search }

/// A themed text input that inherits InputDecoration from the theme.
/// Provides a search variant with debounce, clear, and loading indicator.
class AppInput extends StatefulWidget {
  final String name;
  final String? label;
  final String? hint;
  final AppInputVariant variant;
  final IconData? prefixIcon;
  final bool obscureText;
  final bool enabled;
  final String? initialValue;
  final ValueChanged<String?>? onChanged;
  final Duration debounceDuration;
  final bool isLoading;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;

  const AppInput({
    super.key,
    required this.name,
    this.label,
    this.hint,
    this.variant = AppInputVariant.standard,
    this.prefixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.initialValue,
    this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.isLoading = false,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  Timer? _debounce;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String? value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == AppInputVariant.search) {
      return _buildSearchInput(context);
    }
    return _buildStandardInput();
  }

  Widget _buildStandardInput() {
    return FormBuilderTextField(
      name: widget.name,
      enabled: widget.enabled,
      initialValue: widget.initialValue,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted != null ? (value) => widget.onSubmitted!(value ?? '') : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction ?? TextInputAction.search,
      onSubmitted: widget.onSubmitted,
      onChanged: (value) => _onSearchChanged(value),
      decoration: InputDecoration(
        hintText: widget.hint ?? widget.label,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
              ),
          ],
        ),
      ),
    );
  }
}
