# User Extended-Info Dynamic Form — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `/user/:id/extended-info` route that loads a server-driven form schema bundled with prefilled values, renders all 16 `FormFieldType`s via the existing `DynamicFormRenderer`, and submits via `PUT /admin/users/:id/extended` — closing #121.

**Architecture:** Additive extension of the existing `dynamic_forms` feature: a new `FormBundleEntity`, a second loader method on `IDynamicFormRepository`, a new `LoadFormBundleUseCase`, and a new `DynamicFormLoadBundleEvent` that emits the existing `DynamicFormLoaded` state with an added `initialValues` field. The CRM-lead demo path stays untouched.

**Tech Stack:** Flutter 3.44, Dart 3.12, BLoC, go_router, flutter_form_builder, Equatable, mocktail.

**Approved spec:** `docs/superpowers/specs/2026-05-20-user-extended-info-dynamic-forms-design.md`

---

## File map

**Create:**
- `lib/features/dynamic_forms/domain/entities/form_bundle_entity.dart`
- `lib/features/dynamic_forms/data/models/form_bundle_model.dart`
- `lib/features/dynamic_forms/application/usecases/load_form_bundle_usecase.dart`
- `lib/features/users/presentation/pages/user_extended_info_page.dart`
- `assets/mock/GET_admin_users_extended_pathParams.json`
- `assets/mock/PUT_admin_users_extended_pathParams.json`
- `test/features/dynamic_forms/domain/entities/form_bundle_entity_test.dart`
- `test/features/dynamic_forms/data/models/form_bundle_model_test.dart`
- `test/features/dynamic_forms/application/usecases/load_form_bundle_usecase_test.dart`
- `test/features/users/presentation/pages/user_extended_info_page_test.dart`

**Modify:**
- `lib/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart` (add `fetchBundle`)
- `lib/features/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart` (impl `fetchBundle`)
- `lib/features/dynamic_forms/application/dynamic_form_state.dart` (add `initialValues` field on `DynamicFormLoaded`)
- `lib/features/dynamic_forms/application/dynamic_form_event.dart` (add `DynamicFormLoadBundleEvent`)
- `lib/features/dynamic_forms/application/dynamic_form_bloc.dart` (constructor + handler)
- `lib/features/users/navigation/users_routes.dart` (register `/user/:id/extended-info`)
- `lib/features/users/presentation/pages/user_editor_page.dart` (add "Extended Info" button in edit/view modes)
- `lib/l10n/intl_en.arb` + `lib/l10n/intl_tr.arb` (4 new keys)
- `test/features/dynamic_forms/application/dynamic_form_bloc_test.dart` (cases for bundle path)
- `test/features/dynamic_forms/data/repositories/dynamic_form_repository_impl_test.dart` (cases for `fetchBundle`)
- `test/features/users/navigation/users_feature_routes_test.dart` (case for new route)

---

## Task 1: Domain — `FormBundleEntity`

**Files:**
- Create: `lib/features/dynamic_forms/domain/entities/form_bundle_entity.dart`
- Test: `test/features/dynamic_forms/domain/entities/form_bundle_entity_test.dart`

- [ ] **Step 1: Write the failing test**

File `test/features/dynamic_forms/domain/entities/form_bundle_entity_test.dart`:

```dart
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormBundleEntity', () {
    const schema = FormSchemaEntity(id: 'x', title: 't');

    test('equality holds when schema and values match', () {
      final a = FormBundleEntity(schema: schema, values: const {'k': 1});
      final b = FormBundleEntity(schema: schema, values: const {'k': 1});
      expect(a, equals(b));
    });

    test('inequality when values differ', () {
      final a = FormBundleEntity(schema: schema, values: const {'k': 1});
      final b = FormBundleEntity(schema: schema, values: const {'k': 2});
      expect(a, isNot(equals(b)));
    });

    test('defaults values to empty map', () {
      const bundle = FormBundleEntity(schema: schema);
      expect(bundle.values, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails to compile**

Run: `fvm flutter test test/features/dynamic_forms/domain/entities/form_bundle_entity_test.dart`
Expected: compile error — `Undefined name 'FormBundleEntity'`.

- [ ] **Step 3: Create the entity**

File `lib/features/dynamic_forms/domain/entities/form_bundle_entity.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';

/// A schema bundled with its prefilled values, returned by endpoints that
/// serve server-driven forms whose values live next to their schema
/// (e.g. the user extended-info form).
class FormBundleEntity extends Equatable {
  const FormBundleEntity({required this.schema, this.values = const {}});

  final FormSchemaEntity schema;
  final Map<String, dynamic> values;

  @override
  List<Object?> get props => [schema, values];
}
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `fvm flutter test test/features/dynamic_forms/domain/entities/form_bundle_entity_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dynamic_forms/domain/entities/form_bundle_entity.dart \
        test/features/dynamic_forms/domain/entities/form_bundle_entity_test.dart
git -c commit.gpgsign=false commit -m "feat(dynamic-forms): introduce FormBundleEntity (#121)"
```

---

## Task 2: Data — `FormBundleModel` parser

**Files:**
- Create: `lib/features/dynamic_forms/data/models/form_bundle_model.dart`
- Test: `test/features/dynamic_forms/data/models/form_bundle_model_test.dart`

- [ ] **Step 1: Write the failing test**

File `test/features/dynamic_forms/data/models/form_bundle_model_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_bundle_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormBundleModel.fromJsonString', () {
    test('parses schema + values from a single response body', () {
      final body = jsonEncode({
        'schema': {
          'id': 'user_extended_info',
          'title': 'Extended Information',
          'fields': [
            {'type': 'text', 'key': 'firstName', 'label': 'First name'},
          ],
          'submitAction': {'method': 'PUT', 'endpoint': '/admin/users/:id/extended'},
        },
        'values': {'firstName': 'Alice', 'newsletter': true},
      });

      final bundle = FormBundleModel.fromJsonString(body);

      expect(bundle.schema.id, 'user_extended_info');
      expect(bundle.schema.title, 'Extended Information');
      expect(bundle.schema.fields, hasLength(1));
      expect(bundle.schema.submitAction?.method, 'PUT');
      expect(bundle.values, {'firstName': 'Alice', 'newsletter': true});
    });

    test('defaults values to an empty map when absent', () {
      final body = jsonEncode({
        'schema': {'id': 'x', 'title': 't'},
      });
      final bundle = FormBundleModel.fromJsonString(body);
      expect(bundle.values, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `fvm flutter test test/features/dynamic_forms/data/models/form_bundle_model_test.dart`
Expected: compile error — `FormBundleModel` undefined.

- [ ] **Step 3: Write the parser**

File `lib/features/dynamic_forms/data/models/form_bundle_model.dart`:

```dart
import 'dart:convert';

import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_schema_model.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_bundle_entity.dart';

/// Parses a `{ "schema": {...}, "values": {...} }` response body into a
/// [FormBundleEntity]. The schema is delegated to [FormSchemaModel.fromJson]
/// so that all field-type and layout parsing stays in one place.
class FormBundleModel {
  const FormBundleModel._();

  static FormBundleEntity fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final schemaJson = json['schema'] as Map<String, dynamic>;
    final valuesJson = json['values'] as Map<String, dynamic>? ?? const {};
    return FormBundleEntity(
      schema: FormSchemaModel.fromJson(schemaJson),
      values: Map<String, dynamic>.unmodifiable(valuesJson),
    );
  }
}
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `fvm flutter test test/features/dynamic_forms/data/models/form_bundle_model_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dynamic_forms/data/models/form_bundle_model.dart \
        test/features/dynamic_forms/data/models/form_bundle_model_test.dart
git -c commit.gpgsign=false commit -m "feat(dynamic-forms): parse {schema,values} bundle responses (#121)"
```

---

## Task 3: Data — `DynamicFormRepository.fetchBundle`

**Files:**
- Modify: `lib/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart`
- Modify: `lib/features/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart`
- Modify: `test/features/dynamic_forms/data/repositories/dynamic_form_repository_impl_test.dart`

- [ ] **Step 1: Write the failing tests**

Append to `test/features/dynamic_forms/data/repositories/dynamic_form_repository_impl_test.dart` (inside the existing `main()` group structure — model the structure on existing `fetchSchema` tests in the same file, using the same Dio stubbing setup the file already has):

```dart
group('fetchBundle', () {
  test('returns ValidationError on empty endpoint', () async {
    final repo = DynamicFormRepository();
    final result = await repo.fetchBundle('');
    expect(result, isA<Failure<FormBundleEntity>>());
    final failure = result as Failure<FormBundleEntity>;
    expect(failure.error, isA<ValidationError>());
  });

  test('parses success body into FormBundleEntity', () async {
    // Reuse the stub interceptor pattern already in this file.
    stub.stubSuccess(
      data: jsonEncode({
        'schema': {
          'id': 'user_extended_info',
          'title': 'Extended Information',
          'fields': [
            {'type': 'text', 'key': 'firstName', 'label': 'First name'},
          ],
        },
        'values': {'firstName': 'Alice'},
      }),
    );

    final repo = DynamicFormRepository();
    final result = await repo.fetchBundle('/admin/users/42/extended');

    expect(result, isA<Success<FormBundleEntity>>());
    final success = result as Success<FormBundleEntity>;
    expect(success.data.schema.id, 'user_extended_info');
    expect(success.data.values, {'firstName': 'Alice'});
  });

  test('maps FetchDataException to NetworkError', () async {
    stub.stubDioError(DioExceptionType.connectionTimeout);
    final repo = DynamicFormRepository();
    final result = await repo.fetchBundle('/admin/users/42/extended');
    expect(result, isA<Failure<FormBundleEntity>>());
    expect((result as Failure<FormBundleEntity>).error, isA<NetworkError>());
  });
});
```

Add the missing imports (FormBundleEntity) at the top of the test file.

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `fvm flutter test test/features/dynamic_forms/data/repositories/dynamic_form_repository_impl_test.dart`
Expected: compile error — `fetchBundle` is not a member of `DynamicFormRepository`.

- [ ] **Step 3: Extend the repository interface**

Modify `lib/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart` — add the import and the new method:

```dart
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';

/// Domain port for dynamic-form persistence and dispatch.
///
/// Defined here (domain layer) so the application layer can depend on
/// an abstraction; the data layer provides the HTTP-backed impl.
abstract class IDynamicFormRepository {
  /// Fetch the schema describing the form fields, layout, and submit
  /// action for [formId].
  Future<Result<FormSchemaEntity>> fetchSchema(String formId);

  /// Fetch a schema bundled with prefilled values from [endpoint]. Used by
  /// forms whose schema and values are served together (e.g. user
  /// extended-info).
  Future<Result<FormBundleEntity>> fetchBundle(String endpoint);

  /// Dispatch the user-entered [data] to the submit endpoint described
  /// by [action]. Returns the server response body as a string, or
  /// `null` if the response had no body.
  Future<Result<String?>> submit(FormSubmitAction action, Map<String, dynamic> data);
}
```

- [ ] **Step 4: Implement `fetchBundle`**

Modify `lib/features/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart` — add the import for `FormBundleEntity` and `FormBundleModel`, and add this method alongside `fetchSchema`. The HTTP call uses `ApiClient.get(endpoint)` (absolute path, no `pathParams` — the endpoint is passed in fully formed by the caller):

```dart
import 'package:flutter_bloc_advance/features/dynamic_forms/data/models/form_bundle_model.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_bundle_entity.dart';

// ... (existing imports above)

  static const String endpointRequired = 'Endpoint is required';

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
```

`ApiClient.get` signature (`lib/infrastructure/http/api_client.dart:157`) is `static Future<Response<String>> get(String path, {String? pathParams, Map<String, dynamic>? queryParams})`. Both named params are optional, so `ApiClient.get(endpoint)` is the right call — `endpoint` is already a fully composed absolute path (e.g. `/admin/users/42/extended`) and no further substitution is needed.

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `fvm flutter test test/features/dynamic_forms/data/repositories/dynamic_form_repository_impl_test.dart`
Expected: PASS, all existing tests + 3 new bundle tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart \
        lib/features/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart \
        test/features/dynamic_forms/data/repositories/dynamic_form_repository_impl_test.dart
git -c commit.gpgsign=false commit -m "feat(dynamic-forms): repository.fetchBundle for schema+values endpoints (#121)"
```

---

## Task 4: Application — `LoadFormBundleUseCase`

**Files:**
- Create: `lib/features/dynamic_forms/application/usecases/load_form_bundle_usecase.dart`
- Test: `test/features/dynamic_forms/application/usecases/load_form_bundle_usecase_test.dart`

- [ ] **Step 1: Write the failing test**

File `test/features/dynamic_forms/application/usecases/load_form_bundle_usecase_test.dart`:

```dart
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/usecases/load_form_bundle_usecase.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements IDynamicFormRepository {}

void main() {
  group('LoadFormBundleUseCase', () {
    late _MockRepo repo;
    late LoadFormBundleUseCase useCase;

    setUp(() {
      repo = _MockRepo();
      useCase = LoadFormBundleUseCase(repo);
    });

    test('delegates to repository.fetchBundle with the endpoint', () async {
      const bundle = FormBundleEntity(
        schema: FormSchemaEntity(id: 'x', title: 't'),
        values: {'k': 1},
      );
      when(() => repo.fetchBundle('/admin/users/1/extended')).thenAnswer((_) async => const Success(bundle));

      final result = await useCase('/admin/users/1/extended');

      expect(result, isA<Success<FormBundleEntity>>());
      verify(() => repo.fetchBundle('/admin/users/1/extended')).called(1);
    });

    test('passes through failure from repository', () async {
      when(() => repo.fetchBundle(any())).thenAnswer((_) async => const Failure(NetworkError('boom')));
      final result = await useCase('/x');
      expect(result, isA<Failure<FormBundleEntity>>());
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `fvm flutter test test/features/dynamic_forms/application/usecases/load_form_bundle_usecase_test.dart`
Expected: compile error — `LoadFormBundleUseCase` undefined.

- [ ] **Step 3: Write the use case**

File `lib/features/dynamic_forms/application/usecases/load_form_bundle_usecase.dart`:

```dart
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_bundle_entity.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart';

class LoadFormBundleUseCase {
  const LoadFormBundleUseCase(this._repository);

  final IDynamicFormRepository _repository;

  Future<Result<FormBundleEntity>> call(String endpoint) => _repository.fetchBundle(endpoint);
}
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `fvm flutter test test/features/dynamic_forms/application/usecases/load_form_bundle_usecase_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dynamic_forms/application/usecases/load_form_bundle_usecase.dart \
        test/features/dynamic_forms/application/usecases/load_form_bundle_usecase_test.dart
git -c commit.gpgsign=false commit -m "feat(dynamic-forms): LoadFormBundleUseCase (#121)"
```

---

## Task 5: Application — Bloc handler for bundle loading

**Files:**
- Modify: `lib/features/dynamic_forms/application/dynamic_form_state.dart`
- Modify: `lib/features/dynamic_forms/application/dynamic_form_event.dart`
- Modify: `lib/features/dynamic_forms/application/dynamic_form_bloc.dart`
- Modify: `test/features/dynamic_forms/application/dynamic_form_bloc_test.dart`

- [ ] **Step 1: Write the failing tests**

Append to `test/features/dynamic_forms/application/dynamic_form_bloc_test.dart` (inside the existing `main()` `group('DynamicFormBloc', ...)` block — model on existing load tests in that file, reusing `_StubInterceptor` and `_validFormSchemaJson` patterns):

```dart
group('DynamicFormLoadBundleEvent', () {
  blocTest<DynamicFormBloc, DynamicFormState>(
    'emits [Loading, Loaded(schema, initialValues)] on success',
    setUp: () => stub.stubSuccess(
      data: jsonEncode({
        'schema': jsonDecode(_validFormSchemaJson),
        'values': {'name': 'Alice'},
      }),
    ),
    build: () => DynamicFormBloc(
      loadFormSchemaUseCase: LoadFormSchemaUseCase(DynamicFormRepository()),
      submitFormUseCase: SubmitFormUseCase(DynamicFormRepository()),
      loadFormBundleUseCase: LoadFormBundleUseCase(DynamicFormRepository()),
    ),
    act: (bloc) => bloc.add(const DynamicFormLoadBundleEvent('/admin/users/1/extended')),
    expect: () => [
      isA<DynamicFormLoading>(),
      isA<DynamicFormLoaded>()
          .having((s) => s.schema.id, 'schema.id', 'test_form')
          .having((s) => s.initialValues, 'initialValues', {'name': 'Alice'}),
    ],
  );

  blocTest<DynamicFormBloc, DynamicFormState>(
    'emits [Loading, Failure] when bundle endpoint errors',
    setUp: () => stub.stubDioError(DioExceptionType.connectionTimeout, message: 'timeout'),
    build: () => DynamicFormBloc(
      loadFormSchemaUseCase: LoadFormSchemaUseCase(DynamicFormRepository()),
      submitFormUseCase: SubmitFormUseCase(DynamicFormRepository()),
      loadFormBundleUseCase: LoadFormBundleUseCase(DynamicFormRepository()),
    ),
    act: (bloc) => bloc.add(const DynamicFormLoadBundleEvent('/admin/users/1/extended')),
    expect: () => [
      isA<DynamicFormLoading>(),
      isA<DynamicFormFailure>(),
    ],
  );
});
```

Also update **every existing `DynamicFormBloc(...)` constructor call in this file** to add the `loadFormBundleUseCase:` argument. Run `grep -n 'DynamicFormBloc(' test/features/dynamic_forms/application/dynamic_form_bloc_test.dart` and patch each call.

Add imports at the top:

```dart
import 'package:flutter_bloc_advance/features/dynamic_forms/application/usecases/load_form_bundle_usecase.dart';
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `fvm flutter test test/features/dynamic_forms/application/dynamic_form_bloc_test.dart`
Expected: compile error — `DynamicFormLoadBundleEvent` undefined and `initialValues` not a member of `DynamicFormLoaded`.

- [ ] **Step 3: Extend `DynamicFormLoaded` with `initialValues`**

Modify `lib/features/dynamic_forms/application/dynamic_form_state.dart` — change the `DynamicFormLoaded` class:

```dart
final class DynamicFormLoaded extends DynamicFormState {
  const DynamicFormLoaded({required this.schema, this.initialValues = const {}});

  final FormSchemaEntity schema;
  final Map<String, dynamic> initialValues;

  @override
  List<Object?> get props => [schema, initialValues];
}
```

Default `const {}` keeps every existing call site (the lead-demo path) backward-compatible.

- [ ] **Step 4: Add the new event**

Append to `lib/features/dynamic_forms/application/dynamic_form_event.dart`:

```dart
/// Load a form schema bundled with prefilled values from an absolute endpoint.
class DynamicFormLoadBundleEvent extends DynamicFormEvent {
  const DynamicFormLoadBundleEvent(this.endpoint);
  final String endpoint;
  @override
  List<Object?> get props => [endpoint];
}
```

- [ ] **Step 5: Add the bloc handler**

Modify `lib/features/dynamic_forms/application/dynamic_form_bloc.dart`:

```dart
import 'package:flutter_bloc_advance/features/dynamic_forms/application/usecases/load_form_bundle_usecase.dart';

// ...

class DynamicFormBloc extends Bloc<DynamicFormEvent, DynamicFormState> {
  DynamicFormBloc({
    required this._loadFormSchemaUseCase,
    required this._submitFormUseCase,
    required this._loadFormBundleUseCase,
  }) : super(const DynamicFormInitial()) {
    on<DynamicFormLoadEvent>(_onLoad, transformer: EventTransformers.restart());
    on<DynamicFormLoadBundleEvent>(_onLoadBundle, transformer: EventTransformers.restart());
    on<DynamicFormSubmitEvent>(_onSubmit, transformer: EventTransformers.dropConcurrent());
    on<DynamicFormResetEvent>(_onReset);
  }

  static final _log = AppLogger.getLogger('DynamicFormBloc');

  final LoadFormSchemaUseCase _loadFormSchemaUseCase;
  final SubmitFormUseCase _submitFormUseCase;
  final LoadFormBundleUseCase _loadFormBundleUseCase;

  // existing _onLoad, _onSubmit, _onReset stay unchanged...

  FutureOr<void> _onLoadBundle(DynamicFormLoadBundleEvent event, Emitter<DynamicFormState> emit) async {
    _log.debug('Loading form bundle: {}', [event.endpoint]);
    emit(const DynamicFormLoading());
    final result = await _loadFormBundleUseCase(event.endpoint);
    switch (result) {
      case Success(:final data):
        emit(DynamicFormLoaded(schema: data.schema, initialValues: data.values));
      case Failure(:final error):
        emit(DynamicFormFailure(error: error.message));
    }
  }
}
```

- [ ] **Step 6: Run the bloc tests and confirm they pass**

Run: `fvm flutter test test/features/dynamic_forms/application/dynamic_form_bloc_test.dart`
Expected: PASS, all existing tests + 2 new bundle tests.

- [ ] **Step 7: Check no other call sites are broken**

Run: `fvm dart analyze` (the project-wide analyzer)
Expected: 0 errors. If any test or page constructs `DynamicFormBloc(...)` without the new `loadFormBundleUseCase` parameter, add it. The only known call site outside the bloc test is `lib/features/dynamic_forms/navigation/dynamic_forms_routes.dart:14` (the lead-demo `_withBloc`). Patch it:

```dart
static Widget _withBloc(BuildContext context, Widget child) {
  final repository = context.read<IDynamicFormRepository>();
  return BlocProvider(
    create: (_) => DynamicFormBloc(
      loadFormSchemaUseCase: LoadFormSchemaUseCase(repository),
      submitFormUseCase: SubmitFormUseCase(repository),
      loadFormBundleUseCase: LoadFormBundleUseCase(repository),
    ),
    child: child,
  );
}
```

Add the import for `LoadFormBundleUseCase` at the top of that file.

- [ ] **Step 8: Re-run analyzer and full dynamic-forms test suite**

Run: `fvm dart analyze && fvm flutter test test/features/dynamic_forms/`
Expected: 0 analyzer errors, all dynamic-forms tests green.

- [ ] **Step 9: Commit**

```bash
git add lib/features/dynamic_forms/application/dynamic_form_state.dart \
        lib/features/dynamic_forms/application/dynamic_form_event.dart \
        lib/features/dynamic_forms/application/dynamic_form_bloc.dart \
        lib/features/dynamic_forms/navigation/dynamic_forms_routes.dart \
        test/features/dynamic_forms/application/dynamic_form_bloc_test.dart
git -c commit.gpgsign=false commit -m "feat(dynamic-forms): DynamicFormLoadBundleEvent + initialValues on Loaded (#121)"
```

---

## Task 6: Mock JSON fixtures

**Files:**
- Create: `assets/mock/GET_admin_users_extended_pathParams.json`
- Create: `assets/mock/PUT_admin_users_extended_pathParams.json`

> No tests in this task — the mock is exercised end-to-end by Task 8. `pubspec.yaml` already globs `assets/mock/`, so no manifest change is needed.

- [ ] **Step 1: Create the GET fixture**

File `assets/mock/GET_admin_users_extended_pathParams.json`:

```json
{
  "schema": {
    "id": "user_extended_info",
    "title": "Extended Information",
    "description": "Profile, preferences and security.",
    "layout": "responsive",
    "submitAction": {"method": "PUT", "endpoint": "/admin/users/:id/extended"},
    "fields": [
      {"type": "sectionHeader", "key": "_sec_personal", "label": "Personal"},
      {"type": "text", "key": "firstName", "label": "First name", "readOnly": true},
      {"type": "text", "key": "lastName", "label": "Last name", "readOnly": true},
      {"type": "email", "key": "email", "label": "Email", "required": true},
      {"type": "phone", "key": "phone", "label": "Phone"},
      {"type": "textarea", "key": "bio", "label": "Bio", "maxLines": 4, "hint": "Tell us about yourself"},
      {"type": "date", "key": "birthdate", "label": "Birthdate"},
      {"type": "number", "key": "yearsExperience", "label": "Years of experience", "min": 0, "max": 60},
      {"type": "divider", "key": "_div_1", "label": ""},
      {"type": "sectionHeader", "key": "_sec_prefs", "label": "Preferences"},
      {"type": "dropdown", "key": "country", "label": "Country", "options": ["TR", "US", "DE", "FR", "GB"]},
      {"type": "dropdown", "key": "language", "label": "Language", "options": ["en", "tr", "de"]},
      {"type": "multiSelect", "key": "interests", "label": "Interests", "options": ["flutter", "bloc", "dart", "design"]},
      {"type": "radio", "key": "themePreference", "label": "Theme", "options": ["light", "dark", "system"], "default": "system"},
      {"type": "radio", "key": "accountType", "label": "Account type", "options": ["individual", "business"], "default": "individual"},
      {"type": "slider", "key": "notificationVolume", "label": "Notification volume", "min": 0, "max": 100, "default": 60},
      {"type": "toggle", "key": "newsletter", "label": "Subscribe to newsletter", "default": false},
      {"type": "divider", "key": "_div_2", "label": ""},
      {"type": "sectionHeader", "key": "_sec_security", "label": "Security"},
      {"type": "password", "key": "newPassword", "label": "New password (optional)"},
      {"type": "datetime", "key": "lastLoginOverride", "label": "Override last login"},
      {"type": "checkbox", "key": "acceptTerms", "label": "I accept the terms", "required": true}
    ]
  },
  "values": {
    "firstName": "Alice",
    "lastName": "Liddell",
    "email": "alice@example.com",
    "phone": "+90 555 010 20 30",
    "bio": "Backend engineer, dabbling in Flutter.",
    "birthdate": "1990-01-15",
    "yearsExperience": 8,
    "country": "TR",
    "language": "en",
    "interests": ["flutter", "bloc"],
    "themePreference": "system",
    "accountType": "individual",
    "notificationVolume": 60,
    "newsletter": true,
    "newPassword": null,
    "lastLoginOverride": "2026-05-19T12:30:00Z",
    "acceptTerms": true
  }
}
```

- [ ] **Step 2: Create the PUT fixture**

File `assets/mock/PUT_admin_users_extended_pathParams.json`:

```json
{ "ok": true }
```

- [ ] **Step 3: Commit**

```bash
git add assets/mock/GET_admin_users_extended_pathParams.json \
        assets/mock/PUT_admin_users_extended_pathParams.json
git -c commit.gpgsign=false commit -m "feat(mock): kitchen-sink user-extended-info bundle + put echo (#121)"
```

---

## Task 7: Localization keys

**Files:**
- Modify: `lib/l10n/intl_en.arb`
- Modify: `lib/l10n/intl_tr.arb`
- Regenerate: `lib/generated/` (auto via `intl_utils:generate`)

- [ ] **Step 1: Add EN keys**

Append the following keys to `lib/l10n/intl_en.arb` (just before the closing `}` of the JSON object — match the existing style: each key followed by an `@key` metadata block if other keys in the file use it; otherwise just the key/value):

```json
"user_extended_info_title": "Extended Information",
"user_extended_info_button": "Extended Info",
"user_extended_info_saved": "Saved",
"user_extended_info_save_failed": "Save failed: {error}",
```

Note: the trailing comma matters — the new keys must precede whatever currently terminates the file. Inspect the existing closing keys before pasting and adjust commas accordingly.

- [ ] **Step 2: Add TR keys**

Append the equivalents to `lib/l10n/intl_tr.arb`:

```json
"user_extended_info_title": "Genişletilmiş Bilgi",
"user_extended_info_button": "Genişletilmiş Bilgi",
"user_extended_info_saved": "Kaydedildi",
"user_extended_info_save_failed": "Kayıt başarısız: {error}",
```

- [ ] **Step 3: Regenerate**

Run: `fvm dart run intl_utils:generate`
Expected: `lib/generated/intl/messages_*.dart` and `lib/generated/l10n.dart` updated. No errors.

- [ ] **Step 4: Verify the generated accessors exist**

Run: `grep -n 'user_extended_info_' lib/generated/l10n.dart | head -8`
Expected: 4 matches — one per key.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/intl_en.arb lib/l10n/intl_tr.arb lib/generated/
git -c commit.gpgsign=false commit -m "feat(l10n): user_extended_info_* keys (en, tr) (#121)"
```

---

## Task 8: `UserExtendedInfoPage` + tests

**Files:**
- Create: `lib/features/users/presentation/pages/user_extended_info_page.dart`
- Test: `test/features/users/presentation/pages/user_extended_info_page_test.dart`

- [ ] **Step 1: Write the page test (one happy-path widget test)**

File `test/features/users/presentation/pages/user_extended_info_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_extended_info_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils.dart';

class _MockBloc extends MockBloc<dynamic, DynamicFormState> implements DynamicFormBloc {}

void main() {
  setUpAll(setupUnitTest);
  tearDownAll(tearDownUnitTest);

  Widget host(Widget child, DynamicFormBloc bloc) => MaterialApp(
        home: BlocProvider<DynamicFormBloc>.value(value: bloc, child: child),
      );

  testWidgets('renders loading indicator while bloc is Loading', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const DynamicFormLoading());
    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '1'), bloc));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders form fields when bloc is Loaded', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(
      const DynamicFormLoaded(
        schema: FormSchemaEntity(
          id: 'user_extended_info',
          title: 'Extended Information',
          fields: [
            FormFieldEntity(type: FormFieldType.text, key: 'firstName', label: 'First name'),
          ],
        ),
        initialValues: {'firstName': 'Alice'},
      ),
    );
    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '1'), bloc));
    await tester.pumpAndSettle();
    expect(find.text('First name'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `fvm flutter test test/features/users/presentation/pages/user_extended_info_page_test.dart`
Expected: compile error — `UserExtendedInfoPage` undefined.

- [ ] **Step 3: Write the page**

File `lib/features/users/presentation/pages/user_extended_info_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/presentation/widgets/dynamic_form_renderer.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

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
              context.pop();
            case DynamicFormFailure(:final error, :final schema) when schema != null:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).user_extended_info_save_failed(error))),
              );
            case _:
              break;
          }
        },
        builder: (context, state) => switch (state) {
          DynamicFormInitial() || DynamicFormLoading() =>
              const Center(child: CircularProgressIndicator()),
          DynamicFormLoaded(:final schema, :final initialValues) => _renderForm(schema, initialValues, readOnly: false),
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
```

> The renderer already provides its own "Submit" button when `onSubmit != null && !readOnly` (see `dynamic_form_renderer.dart:42–45`), so the page does not add a duplicate. `_hydrateSchema` is the seam that turns the separate `initialValues` map into per-field `defaultValue`s. Confirm the `FormFieldEntity` constructor signature matches the parameter list above (it's defined in `form_schema_entity.dart`); if any field name diverges, fix the helper to match. The renderer is not modified by this task.

- [ ] **Step 4: Run the test and confirm it passes**

Run: `fvm flutter test test/features/users/presentation/pages/user_extended_info_page_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/users/presentation/pages/user_extended_info_page.dart \
        test/features/users/presentation/pages/user_extended_info_page_test.dart
git -c commit.gpgsign=false commit -m "feat(users): UserExtendedInfoPage rendering dynamic schema+values (#121)"
```

---

## Task 9: Register route `/user/:id/extended-info`

**Files:**
- Modify: `lib/features/users/navigation/users_routes.dart`
- Modify: `test/features/users/navigation/users_feature_routes_test.dart`

- [ ] **Step 1: Write the failing route test**

Append to `test/features/users/navigation/users_feature_routes_test.dart` (model on existing route tests in that file — they typically assert the route name and path exist in `UsersFeatureRoutes.routes`):

```dart
test('registers userExtendedInfo route at /user/:id/extended-info', () {
  final route = UsersFeatureRoutes.routes.firstWhere((r) => r.name == 'userExtendedInfo');
  expect(route.path, '/user/:id/extended-info');
});
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `fvm flutter test test/features/users/navigation/users_feature_routes_test.dart`
Expected: `Bad state: No element` — the route doesn't exist yet.

- [ ] **Step 3: Add the route + dedicated bloc factory**

Modify `lib/features/users/navigation/users_routes.dart`. Add imports:

```dart
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/usecases/load_form_bundle_usecase.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/usecases/load_form_schema_usecase.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/usecases/submit_form_usecase.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_extended_info_page.dart';
```

Inside `UsersFeatureRoutes`, add a new helper alongside `_withListBloc` / `_withEditorBloc`:

```dart
static Widget _withDynamicFormBloc(BuildContext context, Widget child) {
  final repo = context.read<IDynamicFormRepository>();
  return BlocProvider(
    create: (_) => DynamicFormBloc(
      loadFormSchemaUseCase: LoadFormSchemaUseCase(repo),
      submitFormUseCase: SubmitFormUseCase(repo),
      loadFormBundleUseCase: LoadFormBundleUseCase(repo),
    ),
    child: child,
  );
}
```

Add the new route to the end of the `routes` list, before the closing `]`:

```dart
GoRoute(
  name: 'userExtendedInfo',
  path: '/user/:id/extended-info',
  pageBuilder: (context, state) => appTransitionPage(
    state: state,
    type: AppPageTransitionType.slideRight,
    child: _withDynamicFormBloc(
      context,
      UserExtendedInfoPage(userId: state.pathParameters['id']!),
    ),
  ),
),
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `fvm flutter test test/features/users/navigation/users_feature_routes_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/users/navigation/users_routes.dart \
        test/features/users/navigation/users_feature_routes_test.dart
git -c commit.gpgsign=false commit -m "feat(users): /user/:id/extended-info route (#121)"
```

---

## Task 10: "Extended Info" entry button on `UserEditorPage`

**Files:**
- Modify: `lib/features/users/presentation/pages/user_editor_page.dart`
- Test: extend an existing `user_editor_page_test.dart` if one exists, else skip the test step (the route is already covered by Task 9's test and the page by Task 8's tests).

- [ ] **Step 1: Identify the insertion seam**

Run: `grep -n 'EditorFormMode\|_buildFields\|primaryAction\|secondaryAction' lib/features/users/presentation/pages/user_editor_page.dart | head -20`
Expected: a list pointing to roughly line 148 (`primaryAction`/`secondaryAction` on the form header) and line 195 (`_buildFields`).

Approach: add a third action visually **above the field column** as an outlined button, gated on `mode != EditorFormMode.create`. Concretely, modify the `Column` that wraps `_buildFields(context, user)` — wrap it in another `Column` and prepend the button.

Locate the existing block (around line 184):

```dart
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildFields(context, user)),
```

- [ ] **Step 2: Replace it with a button + the existing field column**

Change the block to:

```dart
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    if (widget.mode != EditorFormMode.create && widget.id != null) ...[
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: OutlinedButton.icon(
          key: const Key('userExtendedInfoButtonKey'),
          icon: const Icon(Icons.assignment_outlined),
          label: Text(S.of(context).user_extended_info_button),
          onPressed: () => context.push('/user/${widget.id}/extended-info'),
        ),
      ),
      const SizedBox(height: 16),
    ],
    ..._buildFields(context, user),
  ],
),
```

If `go_router`'s `context.push` import is missing at the top of this file, add it:

```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 3: Verify analyzer is clean**

Run: `fvm dart analyze lib/features/users/presentation/pages/user_editor_page.dart`
Expected: 0 errors.

- [ ] **Step 4: Quick widget smoke test (optional, if `user_editor_page_test.dart` already exists)**

If `test/features/users/presentation/pages/user_editor_page_test.dart` exists, add a small test:

```dart
testWidgets('Extended Info button is visible in edit mode', (tester) async {
  await tester.pumpWidget(hostUserEditor(id: '1', mode: EditorFormMode.edit));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('userExtendedInfoButtonKey')), findsOneWidget);
});

testWidgets('Extended Info button is hidden in create mode', (tester) async {
  await tester.pumpWidget(hostUserEditor(id: null, mode: EditorFormMode.create));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('userExtendedInfoButtonKey')), findsNothing);
});
```

Match the `hostUserEditor` helper to whatever harness the existing file uses (find it with `grep -n 'pumpWidget\|MaterialApp' test/features/users/presentation/pages/user_editor_page_test.dart`). If no editor page test file exists, skip this step.

- [ ] **Step 5: Commit**

```bash
git add lib/features/users/presentation/pages/user_editor_page.dart \
        test/features/users/presentation/pages/user_editor_page_test.dart 2>/dev/null || true
git -c commit.gpgsign=false commit -m "feat(users): Extended Info entry button on user editor (#121)"
```

---

## Task 11: Verify, format, full test suite

- [ ] **Step 1: Format check**

Run: `fvm dart format --line-length=120 --set-exit-if-changed .`
Expected: exit 0. If anything reformats, the CI check will reject the PR. Apply: `fvm dart format --line-length=120 .` then re-run with `--set-exit-if-changed` and commit the format diff as a separate "chore(format): apply dart format" commit if non-trivial.

- [ ] **Step 2: Static analysis**

Run: `fvm dart analyze`
Expected: `No issues found!`

- [ ] **Step 3: Full test suite**

Run: `fvm flutter test`
Expected: `All tests passed!`, with the count being **prior count + new tests added** (Task 1: 3, Task 2: 2, Task 3: 3, Task 4: 2, Task 5: 2, Task 8: 2, Task 9: 1, Task 10: 0–2 ≈ **15–17 new**). Prior baseline per memory: 472. Expect ~487–489 passing.

- [ ] **Step 4: Manual smoke (only if running in an interactive session)**

Run: `fvm flutter run --target lib/main/main_local.dart`
Then in the running app:
1. Log in (default mock credentials).
2. Navigate to Users → pick any user → Edit.
3. Tap **Extended Info** in the top-right of the form.
4. Confirm the form loads with prefilled values across all 16 field types.
5. Edit a few fields, tap **Save**. Confirm snackbar + navigation back to the editor.

Skip this step in non-interactive sessions; the test suite covers the contract.

- [ ] **Step 5: Commit any format/analyzer fixes if needed**

(If steps 1–2 produced changes, commit them now with a `chore(format)` or `chore(analyzer)` message. Otherwise, no commit.)

---

## Task 12: Push and open PR

- [ ] **Step 1: Push the branch**

Run: `git push -u origin feat/121-user-extended-info-dynamic-forms`
Expected: branch pushed; PR URL printed.

- [ ] **Step 2: Open the PR**

Use `gh pr create` with:
- **Title:** `feat(users): dynamic-form kitchen-sink user extended-info (#121)`
- **Body:** structured `## Summary` (bullets: what was added, the additive nature of the dynamic_forms extension, mock interceptor wiring), `## Test plan` checklist (analyze, format, full suite, manual smoke).

Use heredoc to ensure body formatting:

```bash
gh pr create --title "feat(users): dynamic-form kitchen-sink user extended-info (#121)" --body "$(cat <<'EOF'
## Summary
- New `/user/:id/extended-info` route hosting `UserExtendedInfoPage`, reached from a new "Extended Info" outlined button on the user editor (edit/view modes).
- Additive extension of `dynamic_forms`: `FormBundleEntity`, `fetchBundle(endpoint)` on the repository, `LoadFormBundleUseCase`, new `DynamicFormLoadBundleEvent`, and an `initialValues` field on `DynamicFormLoaded` (defaulted, backward-compatible). Existing `/dynamic-forms/:formId` (lead demo) path is untouched.
- Mock fixtures: `GET_admin_users_extended_pathParams.json` returns a schema covering all 16 `FormFieldType`s + a prefilled values payload; `PUT_admin_users_extended_pathParams.json` echoes `{ok: true}`.
- 4 new l10n keys (en, tr).

## Test plan
- [x] `fvm dart format --line-length=120 --set-exit-if-changed .` clean
- [x] `fvm dart analyze` — No issues found
- [x] `fvm flutter test` — 472 prior + ~15 new green
- [ ] Manual smoke: navigate Users → Edit → Extended Info, edit fields, save, confirm round-trip

Closes #121

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 3: Capture the PR URL**

Print the PR URL in the final status update so the user can review it.

---

## Self-review notes (for the planner)

- **Spec coverage:** every section of the design spec (route, button, repo extension, FormBundleEntity, schema covering all 16 types, mock interceptor, l10n, error states, additive bloc changes, acceptance criteria) maps to a numbered task.
- **Type consistency:** `FormBundleEntity({schema, values})`, `IDynamicFormRepository.fetchBundle(String endpoint) → Future<Result<FormBundleEntity>>`, `LoadFormBundleUseCase.call(String endpoint) → Future<Result<FormBundleEntity>>`, `DynamicFormLoadBundleEvent(String endpoint)`, `DynamicFormLoaded({schema, initialValues = const {}})` — same names used end-to-end.
- **Resolved during planning:** (a) `ApiClient.get(String path, {String? pathParams, Map<String, dynamic>? queryParams})` confirmed at `api_client.dart:157` — Task 3 uses `ApiClient.get(endpoint)` with positional path; (b) `DynamicFormRenderer` already renders its own Submit button (`dynamic_form_renderer.dart:42`) and prefills from `field.defaultValue` — Task 8 hydrates the schema's `defaultValue`s from the bundle's `values` rather than modifying the renderer.
