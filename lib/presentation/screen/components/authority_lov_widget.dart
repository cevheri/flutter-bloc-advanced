import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// Dropdown widget for selecting user authorities/roles.
/// Displays available authority options from AuthorityBloc.
/// Updates when authority state changes.
class AuthorityDropdown extends StatelessWidget {
  final bool enabled;

  const AuthorityDropdown({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<AuthorityBloc>(context).add(const AuthorityLoad());
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: BlocBuilder<AuthorityBloc, AuthorityState>(
        builder: (context, state) {
          if (state is AuthorityLoadSuccessState) {
            return FormBuilderDropdown(
              enabled: enabled,
              name: 'authority',
              decoration: InputDecoration(hintText: S.of(context).authorities),
              items: state.authorities.map((role) => DropdownMenuItem(value: role, child: Text(role ?? ""))).toList(),
              initialValue: state.authorities.first,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
