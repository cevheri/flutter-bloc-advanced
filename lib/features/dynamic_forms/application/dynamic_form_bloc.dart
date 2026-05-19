import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_schema_model.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

class DynamicFormBloc extends Bloc<DynamicFormEvent, DynamicFormState> {
  DynamicFormBloc() : super(const DynamicFormInitial()) {
    on<DynamicFormLoadEvent>(_onLoad);
    on<DynamicFormSubmitEvent>(_onSubmit);
    on<DynamicFormResetEvent>(_onReset);
  }

  static final _log = AppLogger.getLogger('DynamicFormBloc');

  FutureOr<void> _onLoad(DynamicFormLoadEvent event, Emitter<DynamicFormState> emit) async {
    _log.debug('Loading form schema: {}', [event.formId]);
    emit(const DynamicFormLoading());
    try {
      final response = await ApiClient.get('/dynamic_forms', pathParams: event.formId);
      final schema = FormSchemaModel.fromJsonString(response.data!);
      emit(DynamicFormLoaded(schema: schema));
    } on AppException catch (e) {
      emit(DynamicFormFailure(error: e.toString()));
    } catch (e) {
      emit(DynamicFormFailure(error: e.toString()));
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

    try {
      final action = schema.submitAction;
      if (action == null) {
        _log.info('No submit action defined — logging form data: {}', [event.data]);
        emit(DynamicFormSubmitted(schema: schema, submitResponse: 'Form data logged'));
        return;
      }

      final response = switch (action.method.toUpperCase()) {
        'POST' => await ApiClient.post(action.endpoint, event.data),
        'PUT' => await ApiClient.put(action.endpoint, event.data),
        'PATCH' => await ApiClient.patch(action.endpoint, event.data),
        'DELETE' => await ApiClient.delete(action.endpoint),
        final method => throw UnsupportedError('Unsupported HTTP method: $method'),
      };

      emit(DynamicFormSubmitted(schema: schema, submitResponse: response.data));
    } on AppException catch (e) {
      emit(DynamicFormFailure(error: e.toString(), schema: schema));
    } catch (e) {
      emit(DynamicFormFailure(error: e.toString(), schema: schema));
    }
  }

  FutureOr<void> _onReset(DynamicFormResetEvent event, Emitter<DynamicFormState> emit) {
    emit(const DynamicFormInitial());
  }
}
