import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/presentation/widgets/dynamic_form_renderer.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

/// Page that hosts a server-driven dynamic form for a single user's
/// extended profile information. Loads schema + prefilled values from
/// `GET /admin/users/:id/extended` and submits via the schema's
/// declared `submitAction`.
class UserExtendedInfoPage extends StatefulWidget {
  const UserExtendedInfoPage({super.key, required this.userId});

  final String userId;

  @override
  State<UserExtendedInfoPage> createState() => _UserExtendedInfoPageState();
}

class _UserExtendedInfoPageState extends State<UserExtendedInfoPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    context.read<DynamicFormBloc>().add(
          DynamicFormLoadBundleEvent('/admin/users/${widget.userId}/extended'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).user_extended_info_saved)),
              );
              if (context.canPop()) context.pop();
            case DynamicFormFailure(:final error, :final schema) when schema != null:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).user_extended_info_save_failed(error))),
              );
            case _:
              break;
          }
        },
        builder: (context, state) => switch (state) {
          DynamicFormInitial() || DynamicFormLoading() => const Center(child: CircularProgressIndicator()),
          DynamicFormLoaded(:final schema, :final initialValues) =>
            _renderForm(schema, initialValues, readOnly: false),
          DynamicFormSubmitting(:final schema) => _renderForm(schema, const {}, readOnly: true),
          DynamicFormSubmitted(:final schema) => _renderForm(schema, const {}, readOnly: true),
          DynamicFormFailure(:final error, :final schema) => schema == null
              ? Center(child: Text(error))
              : _renderForm(schema, const {}, readOnly: false),
        },
      ),
    );
  }

  Widget _renderForm(FormSchemaEntity schema, Map<String, dynamic> values, {required bool readOnly}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DynamicFormRenderer(
        schema: _hydrateSchema(schema, values),
        formKey: _formKey,
        readOnly: readOnly,
        onSubmit: (data) => context.read<DynamicFormBloc>().add(DynamicFormSubmitEvent(data)),
      ),
    );
  }

  /// Merges [values] into each field's `defaultValue` so the renderer
  /// (which prefills from `field.defaultValue`) picks up the bundled
  /// initial values without needing a new public arg.
  FormSchemaEntity _hydrateSchema(FormSchemaEntity schema, Map<String, dynamic> values) {
    if (values.isEmpty) return schema;
    final fields = schema.fields.map((f) {
      if (!values.containsKey(f.key)) return f;
      return FormFieldEntity(
        type: f.type,
        key: f.key,
        label: f.label,
        hint: f.hint,
        required: f.required,
        readOnly: f.readOnly,
        defaultValue: values[f.key],
        options: f.options,
        validators: f.validators,
        maxLines: f.maxLines,
        min: f.min,
        max: f.max,
      );
    }).toList();
    return FormSchemaEntity(
      id: schema.id,
      title: schema.title,
      description: schema.description,
      fields: fields,
      submitAction: schema.submitAction,
      layout: schema.layout,
    );
  }
}
