
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../configuration/app_keys.dart';
import '../../../../generated/l10n.dart';
import 'bloc/task_save_bloc.dart';

class TaskSaveScreen extends StatelessWidget {
  TaskSaveScreen() : super(key: ApplicationKeys.taskSaveScreen);
  final _taskSaveFormKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).taskSaveScreenTitle),
    );
  }

  _buildBody(BuildContext context) {
    return FormBuilder(
      key: _taskSaveFormKey,
      child: Wrap(
        runSpacing: 15,
        children: <Widget>[
          _nameField(context),
          _priceField(context),
          const SizedBox(height: 20),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[_submitButton(context)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameField(BuildContext context) {
    return BlocBuilder<TaskSaveBloc, TaskSaveState>(
        buildWhen: (previous, current) => previous.name != current.name,
        builder: (context, state) {
          return FormBuilderTextField(
              name: 'name',
              decoration: InputDecoration(labelText: S.of(context).taskName),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter name';
                }
                return null;
              });
        });
  }

  Widget _priceField(BuildContext context) {
    return BlocBuilder<TaskSaveBloc, TaskSaveState>(
        buildWhen: (previous, current) => previous.price != current.price,
        builder: (context, state) {
          return FormBuilderTextField(
            name: 'price',
            decoration: InputDecoration(labelText: S.of(context).taskPrice),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter price';
              }
              return null;
            },
            // Add input formatters to allow only numeric values
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
          );
        });
  }

  Widget _submitButton(BuildContext context) {
    return BlocBuilder<TaskSaveBloc, TaskSaveState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          return ElevatedButton(
            child: Text(S.of(context).save),
            onPressed: () {
              if (_taskSaveFormKey.currentState!.saveAndValidate()) {
                context.read<TaskSaveBloc>().add(TaskFormSubmitted(
                      context: context,
                      id: null,
                      name: _taskSaveFormKey.currentState!.value['name'],
                      price: int.tryParse(_taskSaveFormKey.currentState!.value['price'] ?? '') ?? 0,
                    ));
              } else {
                print("validation failed");
              }
            },
          );
        });
  }
}
