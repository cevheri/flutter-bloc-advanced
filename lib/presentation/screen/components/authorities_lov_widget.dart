import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// Dropdown widget for selecting user authorities/roles.
/// Displays available authority options from AuthorityBloc.
/// Updates when authorities state changes.
class AuthoritiesDropdown extends StatefulWidget {
  final bool enabled;
  final String? initialValue;
  final String? hintText;

  const AuthoritiesDropdown({super.key, this.enabled = true, this.initialValue, this.hintText});

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
    return Padding(
      padding: EdgeInsets.zero,
      child: BlocBuilder<AuthorityBloc, AuthorityState>(
        builder: (context, state) {
          if (state is AuthorityLoadSuccessState) {
            final authorities = ["", ...state.authorities];
            return FormBuilderDropdown(
              key: const Key('userEditorAuthoritiesFieldKey'),
              enabled: widget.enabled,
              name: 'authorities',
              decoration: InputDecoration(hintText: widget.hintText ?? S.of(context).authorities),
              items: authorities.map((e) => DropdownMenuItem(value: e, child: Text(e ?? ""))).toList(),
              initialValue: widget.initialValue ?? authorities.first,
              validator: FormBuilderValidators.required(errorText: S.of(context).required_field),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
