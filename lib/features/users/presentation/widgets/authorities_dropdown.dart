import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AuthoritiesDropdown extends StatefulWidget {
  const AuthoritiesDropdown({
    super.key,
    this.enabled = true,
    this.initialValue,
    this.hintText,
    this.isRequired = false,
  });

  final bool enabled;
  final String? initialValue;
  final String? hintText;
  final bool isRequired;

  @override
  State<AuthoritiesDropdown> createState() => _AuthoritiesDropdownState();
}

class _AuthoritiesDropdownState extends State<AuthoritiesDropdown> {
  @override
  void initState() {
    super.initState();
    context.read<AuthorityBloc>().add(const AuthorityLoad());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthorityBloc, AuthorityState>(
      builder: (context, state) {
        if (state is! AuthorityLoadSuccessState) {
          return const SizedBox.shrink();
        }

        final authorities = ['', ...state.authorities];
        final normalizedInitialValue = authorities.contains(widget.initialValue)
            ? widget.initialValue
            : authorities.first;

        return FormBuilderField<String>(
          key: const Key('userEditorAuthoritiesFieldKey'),
          name: 'authorities',
          initialValue: normalizedInitialValue,
          validator: widget.isRequired ? FormBuilderValidators.required(errorText: S.of(context).required_field) : null,
          builder: (field) {
            final cs = Theme.of(context).colorScheme;
            final tt = Theme.of(context).textTheme;
            final selectedValue = field.value ?? '';
            final showPlaceholder = selectedValue.isEmpty;
            final displayText = showPlaceholder ? (widget.hintText ?? S.of(context).authorities) : selectedValue;

            return InkWell(
              onTap: widget.enabled ? () => _openMenu(context, field, authorities) : null,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                isEmpty: showPlaceholder,
                isFocused: false,
                isHovering: false,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? S.of(context).authorities,
                  errorText: field.errorText,
                  enabled: widget.enabled,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ),
                child: Text(
                  displayText,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(color: showPlaceholder ? cs.onSurfaceVariant : cs.onSurface),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openMenu(BuildContext context, FormFieldState<String> field, List<String?> authorities) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final cs = Theme.of(context).colorScheme;
    final currentValue = field.value ?? '';

    final selected = await showMenu<String?>(
      context: context,
      position: position,
      elevation: 6,
      color: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant),
      ),
      items: authorities.map((role) {
        final value = role ?? '';
        final label = value.isEmpty ? (widget.hintText ?? S.of(context).authorities) : value;
        return PopupMenuItem<String?>(
          value: value,
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: value == currentValue
                    ? Icon(Icons.check_rounded, size: 16, color: cs.primary)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      field.didChange(selected);
    }
  }
}
