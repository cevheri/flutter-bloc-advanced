import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_bundle_model.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_schema_model.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

/// HTTP-backed implementation of [IDynamicFormRepository].
///
/// All `ApiException` subtypes are funneled into the typed `Result`
/// pattern that the rest of the codebase uses, removing the
/// `try/catch` dialect from the application layer.
class DynamicFormRepository implements IDynamicFormRepository {
  static final _log = AppLogger.getLogger('DynamicFormRepository');
  static const String _resource = '/dynamic_forms';
  static const String formIdRequired = 'Form id is required';
  static const String submitEndpointRequired = 'Submit action endpoint is required';
  static const String submitMethodRequired = 'Submit action method is required';
  static const String endpointRequired = 'Endpoint is required';

  @override
  Future<Result<FormSchemaEntity>> fetchSchema(String formId) async {
    _log.debug('BEGIN:fetchSchema id: {}', [formId]);
    if (formId.isEmpty) {
      return const Failure(ValidationError(formIdRequired));
    }
    try {
      final response = await ApiClient.get(_resource, pathParams: formId);
      final schema = FormSchemaModel.fromJsonString(response.data!);
      _log.debug('END:fetchSchema successful: {}', [schema.id]);
      return Success(schema);
    } on UnauthorizedException catch (e) {
      _log.error('END:fetchSchema auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:fetchSchema validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:fetchSchema network error: {}', [e]);
      return Failure(NetworkError(e.toString()));
    } catch (e) {
      _log.error('END:fetchSchema unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<FormBundleEntity>> fetchBundle(String endpoint) async {
    _log.debug('BEGIN:fetchBundle endpoint: {}', [endpoint]);
    if (endpoint.isEmpty) {
      return const Failure(ValidationError(endpointRequired));
    }
    try {
      final response = await ApiClient.get(endpoint);
      final bundle = FormBundleModel.fromJsonString(response.data!);
      _log.debug('END:fetchBundle successful: {}', [bundle.schema.id]);
      return Success(bundle);
    } on UnauthorizedException catch (e) {
      _log.error('END:fetchBundle auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:fetchBundle validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:fetchBundle network error: {}', [e]);
      return Failure(NetworkError(e.toString()));
    } catch (e) {
      _log.error('END:fetchBundle unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<String?>> submit(FormSubmitAction action, Map<String, dynamic> data) async {
    _log.debug('BEGIN:submit {} {}', [action.method, action.endpoint]);
    if (action.endpoint.isEmpty) {
      return const Failure(ValidationError(submitEndpointRequired));
    }
    if (action.method.isEmpty) {
      return const Failure(ValidationError(submitMethodRequired));
    }
    try {
      final response = switch (action.method.toUpperCase()) {
        'POST' => await ApiClient.post(action.endpoint, data),
        'PUT' => await ApiClient.put(action.endpoint, data),
        'PATCH' => await ApiClient.patch(action.endpoint, data),
        'DELETE' => await ApiClient.delete(action.endpoint),
        _ => throw UnsupportedError('Unsupported HTTP method: ${action.method}'),
      };
      _log.debug('END:submit successful', []);
      return Success(response.data);
    } on UnsupportedError catch (e) {
      _log.error('END:submit unsupported method: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on UnauthorizedException catch (e) {
      _log.error('END:submit auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:submit validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:submit network error: {}', [e]);
      return Failure(NetworkError(e.toString()));
    } catch (e) {
      _log.error('END:submit unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }
}
