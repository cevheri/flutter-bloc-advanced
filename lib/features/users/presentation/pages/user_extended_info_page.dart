import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/presentation/widgets/dynamic_form_renderer.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

/// Page that hosts a server-driven dynamic form for a single user's
/// extended profile information. Loads schema + prefilled values from
/// `GET /admin/users/extended/{userId}` and submits to the same path via
/// the schema's declared `submitAction`. The per-user path segment is
/// passed through the engine's [DynamicFormLoadBundleEvent.pathParams]
/// channel, so the mock interceptor sees a stable `/admin/users/extended`
/// base and a single fixture serves every user.
class UserExtendedInfoPage extends StatefulWidget {
  const UserExtendedInfoPage({super.key, required this.userId});

  final String userId;

  static const String basePath = '/admin/users/extended';

  @override
  State<UserExtendedInfoPage> createState() => _UserExtendedInfoPageState();
}

class _UserExtendedInfoPageState extends State<UserExtendedInfoPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    context.read<DynamicFormBloc>().add(
      DynamicFormLoadBundleEvent(UserExtendedInfoPage.basePath, pathParams: widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).user_extended_info_title)),
      body: BlocConsumer<DynamicFormBloc, DynamicFormState>(
        listener: (context, state) {
          switch (state) {
            case DynamicFormSubmitted():
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(S.of(context).user_extended_info_saved)));
              if (context.canPop()) context.pop();
            case DynamicFormFailure(:final error, :final schema) when schema != null:
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(S.of(context).user_extended_info_save_failed(error))));
            case _:
              break;
          }
        },
        builder: (context, state) => switch (state) {
          DynamicFormInitial() || DynamicFormLoading() => const Center(child: CircularProgressIndicator()),
          DynamicFormLoaded(:final schema, :final initialValues) => _renderForm(schema, initialValues, readOnly: false),
          DynamicFormSubmitting(:final schema) => _renderForm(schema, const {}, readOnly: true),
          DynamicFormSubmitted(:final schema) => _renderForm(schema, const {}, readOnly: true),
          DynamicFormFailure(:final error, :final schema) =>
            schema == null ? Center(child: Text(error)) : _renderForm(schema, const {}, readOnly: false),
        },
      ),
    );
  }

  Widget _renderForm(FormSchemaEntity schema, Map<String, dynamic> initialValues, {required bool readOnly}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DynamicFormRenderer(
        schema: schema,
        formKey: _formKey,
        readOnly: readOnly,
        initialValues: initialValues,
        onSubmit: (data) => context.read<DynamicFormBloc>().add(DynamicFormSubmitEvent(data)),
      ),
    );
  }
}
