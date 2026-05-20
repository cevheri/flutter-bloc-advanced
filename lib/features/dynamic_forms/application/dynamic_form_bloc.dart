import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/usecases/load_form_schema_usecase.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/usecases/submit_form_usecase.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

class DynamicFormBloc extends Bloc<DynamicFormEvent, DynamicFormState> {
  DynamicFormBloc({required this._loadFormSchemaUseCase, required this._submitFormUseCase})
    : super(const DynamicFormInitial()) {
    on<DynamicFormLoadEvent>(_onLoad, transformer: EventTransformers.restart());
    on<DynamicFormSubmitEvent>(_onSubmit, transformer: EventTransformers.dropConcurrent());
    on<DynamicFormResetEvent>(_onReset);
  }

  static final _log = AppLogger.getLogger('DynamicFormBloc');

  final LoadFormSchemaUseCase _loadFormSchemaUseCase;
  final SubmitFormUseCase _submitFormUseCase;

  FutureOr<void> _onLoad(DynamicFormLoadEvent event, Emitter<DynamicFormState> emit) async {
    _log.debug('Loading form schema: {}', [event.formId]);
    emit(const DynamicFormLoading());
    final result = await _loadFormSchemaUseCase(event.formId);
    switch (result) {
      case Success(:final data):
        emit(DynamicFormLoaded(schema: data));
      case Failure(:final error):
        emit(DynamicFormFailure(error: error.message));
    }
  }

  FutureOr<void> _onSubmit(DynamicFormSubmitEvent event, Emitter<DynamicFormState> emit) async {
    final schema = switch (state) {
      DynamicFormLoaded(:final schema) => schema,
      DynamicFormSubmitted(:final schema) => schema,
      DynamicFormFailure(:final schema?) => schema,
      _ => null,
    };
    if (schema == null) return;

    _log.debug('Submitting form: {}', [schema.id]);
    emit(DynamicFormSubmitting(schema: schema));

    final action = schema.submitAction;
    if (action == null) {
      _log.info('No submit action defined — logging form data: {}', [event.data]);
      emit(DynamicFormSubmitted(schema: schema, submitResponse: 'Form data logged'));
      return;
    }

    final result = await _submitFormUseCase(action, event.data);
    switch (result) {
      case Success(:final data):
        emit(DynamicFormSubmitted(schema: schema, submitResponse: data));
      case Failure(:final error):
        emit(DynamicFormFailure(error: error.message, schema: schema));
    }
  }

  FutureOr<void> _onReset(DynamicFormResetEvent event, Emitter<DynamicFormState> emit) {
    emit(const DynamicFormInitial());
  }
}
