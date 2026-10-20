#!/usr/bin/env dart

// ignore_for_file: avoid_print

// Feature Scaffolding CLI: generates a complete feature skeleton.
//
// Usage, from the project root:
//   dart run tool/generate_feature.dart <feature_name>
//
// Example:
//   dart run tool/generate_feature.dart orders
//
// Generates:
//   lib/features/{feature}/   domain, data, application (list and editor BLoCs over use cases), navigation,
//                             presentation and the feature barrel
//   test/features/{feature}/  BLoC, model, repository and route tests
//   assets/mock/              the mock JSON that MockInterceptor serves for the generated repository's requests
//
// The generated Dart files are formatted with dart format. After generation, follow the printed steps to register
// the repository, the routes, the menu entry and the translations.
//
// test/architecture/feature_generator_test.dart runs this generator and checks that its output is formatted,
// analyzes cleanly and passes its own tests.
import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/generate_feature.dart <feature_name>');
    stderr.writeln('Example: dart run tool/generate_feature.dart orders');
    exit(1);
  }

  final feature = _FeatureNames(args.single.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_'));
  if (!_validName.hasMatch(feature.snake) || !_validName.hasMatch(feature.singularSnake)) {
    stderr.writeln(
      'Invalid feature name "${args.single}": use lowercase words of letters and digits joined by underscores, '
      'starting with a letter, for example orders or purchase_orders.',
    );
    exit(1);
  }

  // Everything the generator writes lives under these paths, so checking them first keeps it from overwriting an
  // existing feature, or the mock files another feature serves, before it has written anything.
  final existing = [
    for (final dir in ['lib/features/${feature.snake}', 'test/features/${feature.snake}'])
      if (Directory(dir).existsSync()) dir,
    for (final mock in [_listMock(feature), _retrieveMock(feature), _createMock(feature), _updateMock(feature)])
      if (File('assets/mock/$mock').existsSync()) 'assets/mock/$mock',
  ];
  if (existing.isNotEmpty) {
    stderr.writeln('Not generating "${feature.snake}": these already exist and would be overwritten:');
    for (final path in existing) {
      stderr.writeln('  $path');
    }
    stderr.writeln('Choose another feature name, or move them away first.');
    exit(1);
  }

  print('');
  print('Generating feature: ${feature.snake}');
  print('=' * 60);

  _generateDomain(feature);
  _generateData(feature);
  _generateApplication(feature);
  _generateNavigation(feature);
  _generatePresentation(feature);
  _generateMockData(feature);
  _generateTests(feature);
  _generateBarrelExport(feature);
  _formatGeneratedCode();
  _printNextSteps(feature);
}

void _printNextSteps(_FeatureNames f) {
  print('');
  print('=' * 60);
  print('Feature "${f.snake}" generated successfully!');
  print('');
  print('NEXT STEPS:');
  print('');
  print('1. Register the repository in lib/app/di/app_dependencies.dart:');
  print(
    "   import 'package:flutter_bloc_advance/features/${f.snake}/data/repositories/${f.singularSnake}_repository.dart';",
  );
  print(
    "   import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';",
  );
  print('');
  print(
    '   I${f.singularPascal}Repository create${f.singularPascal}Repository(ApiClient apiClient) => '
    '${f.singularPascal}Repository(apiClient);',
  );
  print('');
  print('2. Provide it in lib/app/di/app_scope.dart, in MultiRepositoryProvider after the ApiClient provider:');
  print(
    "   import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';",
  );
  print('');
  print('   RepositoryProvider<I${f.singularPascal}Repository>(');
  print('     create: (context) => dependencies.create${f.singularPascal}Repository(context.read<ApiClient>()),');
  print('   ),');
  print('');
  print('3. Register the routes in lib/app/router/app_router.dart, inside ShellRoute.routes:');
  print("   import 'package:flutter_bloc_advance/features/${f.snake}/navigation/${f.snake}_routes.dart';");
  print('   ...${f.pascal}FeatureRoutes.routes,');
  print('');
  print('4. Add the paths to lib/app/router/app_routes_constants.dart for app-level links:');
  print("   static const ${f.camel}List = '/${f.kebab}';");
  print("   static const ${f.camel}New = '/${f.kebab}/new';");
  print("   static const ${f.camel}Edit = '/${f.kebab}/:id/edit';");
  print("   static const ${f.camel}View = '/${f.kebab}/:id/view';");
  print('   For a role-gated feature, also add /${f.kebab} to lib/app/router/route_role_requirements.dart.');
  print('');
  print('5. Add a sidebar menu entry with url /${f.kebab} to assets/mock/menus.json, and a case for its name to');
  print('   translate_menu_title in lib/l10n/intl_en.arb and intl_tr.arb; otherwise the sidebar shows "Other".');
  print('');
  print('6. Move the literal strings in lib/features/${f.snake}/presentation/pages to lib/l10n/intl_en.arb and');
  print('   lib/l10n/intl_tr.arb, then run:');
  print('   fvm dart run intl_utils:generate');
  print('   fvm dart format lib/generated --line-length=120');
  print('');
  print('7. Check the feature:');
  print('   fvm flutter analyze');
  print('   fvm flutter test test/features/${f.snake}');
  print('');
}

// ---------------------------------------------------------------------------
// Name utilities
// ---------------------------------------------------------------------------

/// Lowercase words of letters and digits joined by single underscores, starting with a letter.
final _validName = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

class _FeatureNames {
  _FeatureNames(this.snake);

  final String snake; // purchase_orders

  String get pascal => _toPascal(snake); // PurchaseOrders
  String get camel => _toCamel(snake); // purchaseOrders
  String get kebab => snake.replaceAll('_', '-'); // purchase-orders
  String get title => _toTitle(snake); // Purchase Orders

  String get singularSnake => _singularize(snake); // purchase_order
  String get singularPascal => _toPascal(singularSnake); // PurchaseOrder
  String get singularCamel => _toCamel(singularSnake); // purchaseOrder
  String get singularKebab => singularSnake.replaceAll('_', '-'); // purchase-order
  String get singularTitle => _toTitle(singularSnake); // Purchase Order

  /// REST path of the resource, used by the repository and by the mock asset names.
  String get resourcePath => '/$kebab'; // /purchase-orders
}

String _toPascal(String snake) {
  return snake.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join();
}

String _toCamel(String snake) {
  final pascal = _toPascal(snake);
  if (pascal.isEmpty) return pascal;
  return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
}

String _toTitle(String snake) {
  return snake.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

String _singularize(String word) {
  if (word.endsWith('ies')) return '${word.substring(0, word.length - 3)}y';
  if (word.endsWith('ses') || word.endsWith('xes') || word.endsWith('zes')) return word.substring(0, word.length - 2);
  if (word.endsWith('s') && !word.endsWith('ss')) return word.substring(0, word.length - 1);
  return word;
}

/// The asset MockInterceptor loads for a request: the method and the path with "/" and "-" mapped to "_", then
/// "_pathParams" when the call passes pathParams, otherwise "_queryParams" when it passes queryParams.
/// Mirrors lib/infrastructure/http/interceptors/mock_interceptor.dart.
String _mockAssetName(String method, String path, {bool pathParams = false, bool queryParams = false}) {
  final base = '$method${path.replaceAll('/', '_').replaceAll('-', '_')}';
  if (pathParams) return '${base}_pathParams.json';
  if (queryParams) return '${base}_queryParams.json';
  return '$base.json';
}

// The mock assets for the generated repository's requests. The repository template must make exactly these calls.
String _listMock(_FeatureNames f) => _mockAssetName('GET', f.resourcePath, queryParams: true);
String _retrieveMock(_FeatureNames f) => _mockAssetName('GET', f.resourcePath, pathParams: true);
String _createMock(_FeatureNames f) => _mockAssetName('POST', f.resourcePath);
String _updateMock(_FeatureNames f) => _mockAssetName('PUT', f.resourcePath);

// ---------------------------------------------------------------------------
// File generation
// ---------------------------------------------------------------------------

final _createdFiles = <String>[];

void _writeFile(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  _createdFiles.add(path);
  print('  Created: $path');
}

/// Formats the generated Dart files the way CI checks them, so the output does not depend on how a template line
/// wraps for a given feature name.
void _formatGeneratedCode() {
  final dartFiles = _createdFiles.where((path) => path.endsWith('.dart')).toList();
  final result = Process.runSync(Platform.resolvedExecutable, ['format', '--line-length=120', ...dartFiles]);
  if (result.exitCode != 0) {
    stderr.writeln('dart format failed on the generated files:');
    stderr.write(result.stdout);
    stderr.write(result.stderr);
    exit(1);
  }
  print('\nFormatted ${dartFiles.length} Dart files.');
}

// ---------------------------------------------------------------------------
// Domain Layer
// ---------------------------------------------------------------------------

void _generateDomain(_FeatureNames f) {
  print('\nDomain layer:');

  // Entity
  _writeFile('lib/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart', '''
import 'package:equatable/equatable.dart';

class ${f.singularPascal}Entity extends Equatable {
  const ${f.singularPascal}Entity({this.id, this.name, this.description, this.createdDate, this.lastModifiedDate});

  final String? id;
  final String? name;
  final String? description;
  final DateTime? createdDate;
  final DateTime? lastModifiedDate;

  ${f.singularPascal}Entity copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) {
    return ${f.singularPascal}Entity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }

  @override
  List<Object?> get props => [id, name, description, createdDate, lastModifiedDate];
}
''');

  // Repository interface
  _writeFile('lib/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart', '''
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';

abstract class I${f.singularPascal}Repository {
  Future<Result<${f.singularPascal}Entity>> retrieve(String id);

  Future<Result<${f.singularPascal}Entity>> create(${f.singularPascal}Entity entity);

  Future<Result<${f.singularPascal}Entity>> update(${f.singularPascal}Entity entity);

  Future<Result<List<${f.singularPascal}Entity>>> list({int page = 0, int size = 10});

  Future<Result<void>> delete(String id);
}
''');
}

// ---------------------------------------------------------------------------
// Data Layer
// ---------------------------------------------------------------------------

void _generateData(_FeatureNames f) {
  print('\nData layer:');

  // Model
  _writeFile('lib/features/${f.snake}/data/models/${f.singularSnake}_model.dart', '''
import 'dart:convert';

import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';

class ${f.singularPascal}Model extends ${f.singularPascal}Entity {
  const ${f.singularPascal}Model({super.id, super.name, super.description, super.createdDate, super.lastModifiedDate});

  factory ${f.singularPascal}Model.fromEntity(${f.singularPascal}Entity entity) => ${f.singularPascal}Model(
    id: entity.id,
    name: entity.name,
    description: entity.description,
    createdDate: entity.createdDate,
    lastModifiedDate: entity.lastModifiedDate,
  );

  static ${f.singularPascal}Model fromJson(Map<String, dynamic> json) => ${f.singularPascal}Model(
    id: json['id'] as String?,
    name: json['name'] as String?,
    description: json['description'] as String?,
    createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
    lastModifiedDate: json['lastModifiedDate'] == null ? null : DateTime.parse(json['lastModifiedDate'] as String),
  );

  static ${f.singularPascal}Model fromJsonString(String jsonString) =>
      fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  static List<${f.singularPascal}Model> fromJsonList(List<dynamic> jsonList) =>
      jsonList.map((json) => fromJson(json as Map<String, dynamic>)).toList();

  static List<${f.singularPascal}Model> fromJsonStringList(String jsonString) =>
      fromJsonList(jsonDecode(jsonString) as List<dynamic>);

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
    if (lastModifiedDate != null) 'lastModifiedDate': lastModifiedDate!.toIso8601String(),
  };

  @override
  bool get stringify => true;
}
''');

  // Repository implementation
  _writeFile('lib/features/${f.snake}/data/repositories/${f.singularSnake}_repository.dart', '''
import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/data/models/${f.singularSnake}_model.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

/// HTTP-backed [I${f.singularPascal}Repository].
///
/// In dev and test, MockInterceptor answers these calls from assets/mock/:
/// - list: ${_listMock(f)}
/// - retrieve: ${_retrieveMock(f)}
/// - create: ${_createMock(f)}
/// - update: ${_updateMock(f)}
/// - delete needs no file.
class ${f.singularPascal}Repository implements I${f.singularPascal}Repository {
  ${f.singularPascal}Repository(this._apiClient);

  final ApiClient _apiClient;

  static final _log = AppLogger.getLogger('${f.singularPascal}Repository');
  static const String _resource = '${f.resourcePath}';

  @override
  Future<Result<${f.singularPascal}Entity>> retrieve(String id) async {
    _log.debug('BEGIN:retrieve id: {}', [id]);
    try {
      final response = await _apiClient.get(_resource, pathParams: id);
      final result = ${f.singularPascal}Model.fromJsonString(response.data!);
      _log.debug('END:retrieve successful id: {}', [result.id]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:retrieve auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:retrieve validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:retrieve network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:retrieve unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<${f.singularPascal}Entity>> create(${f.singularPascal}Entity entity) async {
    _log.debug('BEGIN:create');
    try {
      // Pass idempotent: true only when the backend deduplicates by Idempotency-Key (see README).
      final response = await _apiClient.post<${f.singularPascal}Model>(_resource, ${f.singularPascal}Model.fromEntity(entity));
      final result = ${f.singularPascal}Model.fromJsonString(response.data!);
      _log.debug('END:create successful id: {}', [result.id]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:create auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:create validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:create network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:create unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<${f.singularPascal}Entity>> update(${f.singularPascal}Entity entity) async {
    _log.debug('BEGIN:update id: {}', [entity.id]);
    try {
      final response = await _apiClient.put<${f.singularPascal}Model>(_resource, ${f.singularPascal}Model.fromEntity(entity));
      final result = ${f.singularPascal}Model.fromJsonString(response.data!);
      _log.debug('END:update successful id: {}', [result.id]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:update auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:update validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:update network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:update unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<${f.singularPascal}Entity>>> list({int page = 0, int size = 10}) async {
    _log.debug('BEGIN:list page: {}, size: {}', [page, size]);
    try {
      final queryParams = {'page': page.toString(), 'size': size.toString()};
      final response = await _apiClient.get(_resource, queryParams: queryParams);
      final result = ${f.singularPascal}Model.fromJsonStringList(response.data!);
      _log.debug('END:list successful count: {}', [result.length]);
      return Success(result);
    } on UnauthorizedException catch (e) {
      _log.error('END:list auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:list validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:list network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:list unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    _log.debug('BEGIN:delete id: {}', [id]);
    try {
      await _apiClient.delete(_resource, pathParams: id);
      _log.debug('END:delete successful id: {}', [id]);
      return const Success(null);
    } on UnauthorizedException catch (e) {
      _log.error('END:delete auth error: {}', [e]);
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      _log.error('END:delete validation error: {}', [e]);
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      _log.error('END:delete network error: {}', [e]);
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      _log.error('END:delete unknown error: {}', [e]);
      return Failure(UnknownError(e.toString()));
    }
  }

  static AppError _mapFetchDataException(FetchDataException e) {
    final message = e.toString().toLowerCase();
    if (message.contains('timeout')) return TimeoutError(e.toString());
    return NetworkError(e.toString());
  }
}
''');
}

// ---------------------------------------------------------------------------
// Application Layer
// ---------------------------------------------------------------------------

void _generateApplication(_FeatureNames f) {
  print('\nApplication layer:');

  // Use cases
  _writeFile('lib/features/${f.snake}/application/usecases/list_${f.snake}_usecase.dart', '''
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';

class List${f.pascal}UseCase {
  const List${f.pascal}UseCase(this._repository);

  final I${f.singularPascal}Repository _repository;

  Future<Result<List<${f.singularPascal}Entity>>> call({int page = 0, int size = 10}) {
    return _repository.list(page: page, size: size);
  }
}
''');

  _writeFile('lib/features/${f.snake}/application/usecases/fetch_${f.singularSnake}_usecase.dart', '''
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';

class Fetch${f.singularPascal}UseCase {
  const Fetch${f.singularPascal}UseCase(this._repository);

  final I${f.singularPascal}Repository _repository;

  Future<Result<${f.singularPascal}Entity>> call(String id) {
    return _repository.retrieve(id);
  }
}
''');

  _writeFile('lib/features/${f.snake}/application/usecases/save_${f.singularSnake}_usecase.dart', '''
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';

/// Creates the ${f.singularTitle.toLowerCase()} when it has no id, updates it otherwise.
class Save${f.singularPascal}UseCase {
  const Save${f.singularPascal}UseCase(this._repository);

  final I${f.singularPascal}Repository _repository;

  Future<Result<${f.singularPascal}Entity>> call(${f.singularPascal}Entity entity) {
    if (entity.id == null) {
      return _repository.create(entity);
    }
    return _repository.update(entity);
  }
}
''');

  _writeFile('lib/features/${f.snake}/application/usecases/delete_${f.singularSnake}_usecase.dart', '''
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';

class Delete${f.singularPascal}UseCase {
  const Delete${f.singularPascal}UseCase(this._repository);

  final I${f.singularPascal}Repository _repository;

  Future<Result<void>> call(String id) {
    return _repository.delete(id);
  }
}
''');

  // List BLoC
  _writeFile('lib/features/${f.snake}/application/${f.singularSnake}_list_bloc.dart', '''
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/delete_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/list_${f.snake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

part '${f.singularSnake}_list_event.dart';
part '${f.singularSnake}_list_state.dart';

/// Bloc for the ${f.title.toLowerCase()} list page: loads the list and deletes rows from it.
///
/// Create, edit and view belong to ${f.singularPascal}EditorBloc.
class ${f.singularPascal}ListBloc extends Bloc<${f.singularPascal}ListEvent, ${f.singularPascal}ListState> {
  ${f.singularPascal}ListBloc({required this._list${f.pascal}UseCase, required this._delete${f.singularPascal}UseCase})
    : super(const ${f.singularPascal}ListInitial()) {
    on<${f.singularPascal}ListLoad>(_onLoad, transformer: EventTransformers.restart());
    on<${f.singularPascal}ListDelete>(_onDelete, transformer: EventTransformers.dropConcurrent());
  }

  static final _log = AppLogger.getLogger('${f.singularPascal}ListBloc');

  final List${f.pascal}UseCase _list${f.pascal}UseCase;
  final Delete${f.singularPascal}UseCase _delete${f.singularPascal}UseCase;

  FutureOr<void> _onLoad(${f.singularPascal}ListLoad event, Emitter<${f.singularPascal}ListState> emit) async {
    _log.debug('BEGIN: onLoad page: {}, size: {}', [event.page, event.size]);
    emit(const ${f.singularPascal}ListLoading());
    final result = await _list${f.pascal}UseCase(page: event.page, size: event.size);
    switch (result) {
      case Success(:final data):
        emit(${f.singularPascal}ListLoaded(items: data));
        _log.debug('END: onLoad success count: {}', [data.length]);
      case Failure(:final error):
        emit(${f.singularPascal}ListFailure(error: error.message));
        _log.error('END: onLoad error: {}', [error.message]);
    }
  }

  FutureOr<void> _onDelete(${f.singularPascal}ListDelete event, Emitter<${f.singularPascal}ListState> emit) async {
    _log.debug('BEGIN: onDelete id: {}', [event.id]);
    emit(const ${f.singularPascal}ListLoading());
    final result = await _delete${f.singularPascal}UseCase(event.id);
    switch (result) {
      case Success():
        emit(const ${f.singularPascal}ListDeleteSuccess());
        _log.debug('END: onDelete success id: {}', [event.id]);
      case Failure(:final error):
        emit(${f.singularPascal}ListFailure(error: error.message));
        _log.error('END: onDelete error: {}', [error.message]);
    }
  }
}
''');

  _writeFile('lib/features/${f.snake}/application/${f.singularSnake}_list_event.dart', '''
part of '${f.singularSnake}_list_bloc.dart';

sealed class ${f.singularPascal}ListEvent extends Equatable {
  const ${f.singularPascal}ListEvent();
}

final class ${f.singularPascal}ListLoad extends ${f.singularPascal}ListEvent {
  const ${f.singularPascal}ListLoad({this.page = 0, this.size = 10});

  final int page;
  final int size;

  @override
  List<Object?> get props => [page, size];
}

final class ${f.singularPascal}ListDelete extends ${f.singularPascal}ListEvent {
  const ${f.singularPascal}ListDelete(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
''');

  _writeFile('lib/features/${f.snake}/application/${f.singularSnake}_list_state.dart', '''
part of '${f.singularSnake}_list_bloc.dart';

sealed class ${f.singularPascal}ListState extends Equatable {
  const ${f.singularPascal}ListState();
}

final class ${f.singularPascal}ListInitial extends ${f.singularPascal}ListState {
  const ${f.singularPascal}ListInitial();

  @override
  List<Object?> get props => const [];
}

final class ${f.singularPascal}ListLoading extends ${f.singularPascal}ListState {
  const ${f.singularPascal}ListLoading();

  @override
  List<Object?> get props => const [];
}

final class ${f.singularPascal}ListLoaded extends ${f.singularPascal}ListState {
  const ${f.singularPascal}ListLoaded({required this.items});

  final List<${f.singularPascal}Entity> items;

  @override
  List<Object?> get props => [items];
}

/// Emitted after a successful delete. The list page reloads the list on it.
final class ${f.singularPascal}ListDeleteSuccess extends ${f.singularPascal}ListState {
  const ${f.singularPascal}ListDeleteSuccess();

  @override
  List<Object?> get props => const [];
}

final class ${f.singularPascal}ListFailure extends ${f.singularPascal}ListState {
  const ${f.singularPascal}ListFailure({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}
''');

  // Editor BLoC
  _writeFile('lib/features/${f.snake}/application/${f.singularSnake}_editor_bloc.dart', '''
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/fetch_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/save_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

part '${f.singularSnake}_editor_event.dart';
part '${f.singularSnake}_editor_state.dart';

/// Bloc for the create, edit and view pages: fetches the ${f.singularTitle.toLowerCase()} to show and saves the form.
///
/// Delete belongs to ${f.singularPascal}ListBloc, where the action is invoked and the list is reloaded.
class ${f.singularPascal}EditorBloc extends Bloc<${f.singularPascal}EditorEvent, ${f.singularPascal}EditorState> {
  ${f.singularPascal}EditorBloc({required this._fetch${f.singularPascal}UseCase, required this._save${f.singularPascal}UseCase})
    : super(const ${f.singularPascal}EditorInitial()) {
    on<${f.singularPascal}EditorFetch>(_onFetch, transformer: EventTransformers.restart());
    on<${f.singularPascal}EditorSubmit>(_onSubmit, transformer: EventTransformers.dropConcurrent());
  }

  static final _log = AppLogger.getLogger('${f.singularPascal}EditorBloc');

  final Fetch${f.singularPascal}UseCase _fetch${f.singularPascal}UseCase;
  final Save${f.singularPascal}UseCase _save${f.singularPascal}UseCase;

  FutureOr<void> _onFetch(${f.singularPascal}EditorFetch event, Emitter<${f.singularPascal}EditorState> emit) async {
    _log.debug('BEGIN: onFetch id: {}', [event.id]);
    emit(const ${f.singularPascal}EditorLoading());
    final result = await _fetch${f.singularPascal}UseCase(event.id);
    switch (result) {
      case Success(:final data):
        emit(${f.singularPascal}EditorLoaded(data: data));
        _log.debug('END: onFetch success id: {}', [data.id]);
      case Failure(:final error):
        emit(${f.singularPascal}EditorLoadFailure(error: error.message));
        _log.error('END: onFetch error: {}', [error.message]);
    }
  }

  FutureOr<void> _onSubmit(${f.singularPascal}EditorSubmit event, Emitter<${f.singularPascal}EditorState> emit) async {
    _log.debug('BEGIN: onSubmit id: {}', [event.data.id]);
    emit(${f.singularPascal}EditorSaving(data: event.data));
    final result = await _save${f.singularPascal}UseCase(event.data);
    switch (result) {
      case Success(:final data):
        emit(${f.singularPascal}EditorSaved(data: data));
        _log.debug('END: onSubmit success id: {}', [data.id]);
      case Failure(:final error):
        emit(${f.singularPascal}EditorSaveFailure(error: error.message, data: event.data));
        _log.error('END: onSubmit error: {}', [error.message]);
    }
  }
}
''');

  _writeFile('lib/features/${f.snake}/application/${f.singularSnake}_editor_event.dart', '''
part of '${f.singularSnake}_editor_bloc.dart';

sealed class ${f.singularPascal}EditorEvent extends Equatable {
  const ${f.singularPascal}EditorEvent();
}

final class ${f.singularPascal}EditorFetch extends ${f.singularPascal}EditorEvent {
  const ${f.singularPascal}EditorFetch(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Creates the ${f.singularTitle.toLowerCase()} when [data] has no id, updates it otherwise.
final class ${f.singularPascal}EditorSubmit extends ${f.singularPascal}EditorEvent {
  const ${f.singularPascal}EditorSubmit(this.data);

  final ${f.singularPascal}Entity data;

  @override
  List<Object?> get props => [data];
}
''');

  _writeFile('lib/features/${f.snake}/application/${f.singularSnake}_editor_state.dart', '''
part of '${f.singularSnake}_editor_bloc.dart';

sealed class ${f.singularPascal}EditorState extends Equatable {
  const ${f.singularPascal}EditorState();
}

/// Nothing fetched: the create page starts here with an empty form.
final class ${f.singularPascal}EditorInitial extends ${f.singularPascal}EditorState {
  const ${f.singularPascal}EditorInitial();

  @override
  List<Object?> get props => const [];
}

/// The ${f.singularTitle.toLowerCase()} for the edit or view page is being fetched.
final class ${f.singularPascal}EditorLoading extends ${f.singularPascal}EditorState {
  const ${f.singularPascal}EditorLoading();

  @override
  List<Object?> get props => const [];
}

final class ${f.singularPascal}EditorLoaded extends ${f.singularPascal}EditorState {
  const ${f.singularPascal}EditorLoaded({required this.data});

  final ${f.singularPascal}Entity data;

  @override
  List<Object?> get props => [data];
}

/// A submit is in flight. Carries the submitted ${f.singularTitle.toLowerCase()} so the form keeps showing it.
final class ${f.singularPascal}EditorSaving extends ${f.singularPascal}EditorState {
  const ${f.singularPascal}EditorSaving({required this.data});

  final ${f.singularPascal}Entity data;

  @override
  List<Object?> get props => [data];
}

final class ${f.singularPascal}EditorSaved extends ${f.singularPascal}EditorState {
  const ${f.singularPascal}EditorSaved({required this.data});

  final ${f.singularPascal}Entity data;

  @override
  List<Object?> get props => [data];
}

/// The fetch failed, so there is no ${f.singularTitle.toLowerCase()} to show.
final class ${f.singularPascal}EditorLoadFailure extends ${f.singularPascal}EditorState {
  const ${f.singularPascal}EditorLoadFailure({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}

/// The submit failed. Carries the submitted ${f.singularTitle.toLowerCase()} so the user can correct and resend it.
final class ${f.singularPascal}EditorSaveFailure extends ${f.singularPascal}EditorState {
  const ${f.singularPascal}EditorSaveFailure({required this.error, required this.data});

  final String error;
  final ${f.singularPascal}Entity data;

  @override
  List<Object?> get props => [error, data];
}
''');
}

// ---------------------------------------------------------------------------
// Navigation Layer
// ---------------------------------------------------------------------------

void _generateNavigation(_FeatureNames f) {
  print('\nNavigation layer:');

  _writeFile('lib/features/${f.snake}/navigation/${f.snake}_routes.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_editor_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_list_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/delete_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/fetch_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/list_${f.snake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/save_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/presentation/pages/${f.singularSnake}_editor_page.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/presentation/pages/${f.singularSnake}_list_page.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/shared/widgets/editor_form_mode.dart';
import 'package:go_router/go_router.dart';

/// Routes of the ${f.title.toLowerCase()} feature, for the ShellRoute in lib/app/router/app_router.dart.
///
/// Each route builds its BLoC from the [I${f.singularPascal}Repository] that lib/app/di/app_scope.dart provides.
class ${f.pascal}FeatureRoutes {
  static Widget _withListBloc(BuildContext context, Widget child) {
    final repository = context.read<I${f.singularPascal}Repository>();
    return BlocProvider(
      create: (_) => ${f.singularPascal}ListBloc(
        list${f.pascal}UseCase: List${f.pascal}UseCase(repository),
        delete${f.singularPascal}UseCase: Delete${f.singularPascal}UseCase(repository),
      ),
      child: child,
    );
  }

  static Widget _withEditorBloc(BuildContext context, Widget child) {
    final repository = context.read<I${f.singularPascal}Repository>();
    return BlocProvider(
      create: (_) => ${f.singularPascal}EditorBloc(
        fetch${f.singularPascal}UseCase: Fetch${f.singularPascal}UseCase(repository),
        save${f.singularPascal}UseCase: Save${f.singularPascal}UseCase(repository),
      ),
      child: child,
    );
  }

  static final List<GoRoute> routes = <GoRoute>[
    GoRoute(
      name: '${f.camel}List',
      path: '/${f.kebab}',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.fade,
        child: _withListBloc(context, const ${f.singularPascal}ListPage()),
      ),
    ),
    GoRoute(
      name: '${f.camel}Create',
      path: '/${f.kebab}/new',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withEditorBloc(context, const ${f.singularPascal}EditorPage(mode: EditorFormMode.create)),
      ),
    ),
    GoRoute(
      name: '${f.camel}Edit',
      path: '/${f.kebab}/:id/edit',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withEditorBloc(context, ${f.singularPascal}EditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.edit)),
      ),
    ),
    GoRoute(
      name: '${f.camel}View',
      path: '/${f.kebab}/:id/view',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withEditorBloc(context, ${f.singularPascal}EditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.view)),
      ),
    ),
  ];
}
''');
}

// ---------------------------------------------------------------------------
// Presentation Layer
// ---------------------------------------------------------------------------

void _generatePresentation(_FeatureNames f) {
  print('\nPresentation layer:');

  // List page
  _writeFile('lib/features/${f.snake}/presentation/pages/${f.singularSnake}_list_page.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_list_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_empty_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/widgets/confirmation_dialog_widget.dart';
import 'package:go_router/go_router.dart';

class ${f.singularPascal}ListPage extends StatefulWidget {
  const ${f.singularPascal}ListPage({super.key});

  @override
  State<${f.singularPascal}ListPage> createState() => _${f.singularPascal}ListPageState();
}

class _${f.singularPascal}ListPageState extends State<${f.singularPascal}ListPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => context.read<${f.singularPascal}ListBloc>().add(const ${f.singularPascal}ListLoad());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${f.title}', style: Theme.of(context).textTheme.headlineSmall)),
              AppButton(
                key: const Key('${f.singularCamel}ListCreateButtonKey'),
                label: 'New ${f.singularTitle}',
                icon: Icons.add,
                onPressed: () => context.goNamed('${f.camel}Create'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: BlocConsumer<${f.singularPascal}ListBloc, ${f.singularPascal}ListState>(
              listener: _onStateChanged,
              builder: (context, state) => switch (state) {
                ${f.singularPascal}ListInitial() || ${f.singularPascal}ListLoading() || ${f.singularPascal}ListDeleteSuccess() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ${f.singularPascal}ListLoaded(:final items) when items.isEmpty => AppEmptyState(title: S.of(context).no_data),
                ${f.singularPascal}ListLoaded(:final items) => _${f.singularPascal}ListView(items: items),
                ${f.singularPascal}ListFailure(:final error) => AppErrorState(description: error, onRetry: _load),
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onStateChanged(BuildContext context, ${f.singularPascal}ListState state) {
    switch (state) {
      case ${f.singularPascal}ListDeleteSuccess():
        _load();
      case ${f.singularPascal}ListInitial() || ${f.singularPascal}ListLoading() || ${f.singularPascal}ListLoaded() || ${f.singularPascal}ListFailure():
        break;
    }
  }
}

class _${f.singularPascal}ListView extends StatelessWidget {
  const _${f.singularPascal}ListView({required this.items});

  final List<${f.singularPascal}Entity> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item.id!;
        return ListTile(
          title: Text(item.name ?? ''),
          subtitle: item.description == null ? null : Text(item.description!),
          onTap: () => context.goNamed('${f.camel}View', pathParameters: {'id': id}),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.goNamed('${f.camel}Edit', pathParameters: {'id': id}),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, id),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await ConfirmationDialog.show(context: context, type: DialogType.delete);
    if (confirmed == true && context.mounted) {
      context.read<${f.singularPascal}ListBloc>().add(${f.singularPascal}ListDelete(id));
    }
  }
}
''');

  // Editor page
  _writeFile('lib/features/${f.snake}/presentation/pages/${f.singularSnake}_editor_page.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_editor_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/widgets/editor_form_mode.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

class ${f.singularPascal}EditorPage extends StatefulWidget {
  const ${f.singularPascal}EditorPage({super.key, this.id, required this.mode});

  /// The ${f.singularTitle.toLowerCase()} to edit or view; null on the create page.
  final String? id;
  final EditorFormMode mode;

  @override
  State<${f.singularPascal}EditorPage> createState() => _${f.singularPascal}EditorPageState();
}

class _${f.singularPascal}EditorPageState extends State<${f.singularPascal}EditorPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  bool get _readOnly => widget.mode == EditorFormMode.view;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    final id = widget.id;
    if (id != null) {
      context.read<${f.singularPascal}EditorBloc>().add(${f.singularPascal}EditorFetch(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<${f.singularPascal}EditorBloc, ${f.singularPascal}EditorState>(
      listener: _onStateChanged,
      builder: (context, state) => switch (state) {
        ${f.singularPascal}EditorInitial() when widget.id != null => const Center(child: CircularProgressIndicator()),
        ${f.singularPascal}EditorInitial() => _buildForm(context, null, isSaving: false),
        ${f.singularPascal}EditorLoading() => const Center(child: CircularProgressIndicator()),
        ${f.singularPascal}EditorLoaded(:final data) => _buildForm(context, data, isSaving: false),
        ${f.singularPascal}EditorSaving(:final data) => _buildForm(context, data, isSaving: true),
        ${f.singularPascal}EditorSaved(:final data) => _buildForm(context, data, isSaving: false),
        ${f.singularPascal}EditorLoadFailure(:final error) => AppErrorState(description: error, onRetry: _fetch),
        ${f.singularPascal}EditorSaveFailure(:final data) => _buildForm(context, data, isSaving: false),
      },
    );
  }

  void _onStateChanged(BuildContext context, ${f.singularPascal}EditorState state) {
    switch (state) {
      case ${f.singularPascal}EditorSaved():
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).success)));
        context.goNamed('${f.camel}List');
      case ${f.singularPascal}EditorSaveFailure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      case ${f.singularPascal}EditorInitial() ||
          ${f.singularPascal}EditorLoading() ||
          ${f.singularPascal}EditorLoaded() ||
          ${f.singularPascal}EditorSaving() ||
          ${f.singularPascal}EditorLoadFailure():
        break;
    }
  }

  Widget _buildForm(BuildContext context, ${f.singularPascal}Entity? data, {required bool isSaving}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xl),
            FormBuilderTextField(
              key: const Key('${f.singularCamel}EditorNameFieldKey'),
              name: 'name',
              initialValue: data?.name,
              readOnly: _readOnly,
              decoration: InputDecoration(labelText: S.of(context).name),
              validator: FormBuilderValidators.required(errorText: S.of(context).required_field),
            ),
            const SizedBox(height: AppSpacing.lg),
            FormBuilderTextField(
              key: const Key('${f.singularCamel}EditorDescriptionFieldKey'),
              name: 'description',
              initialValue: data?.description,
              readOnly: _readOnly,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            if (!_readOnly) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                key: const Key('${f.singularCamel}EditorSubmitButtonKey'),
                label: S.of(context).save,
                isLoading: isSaving,
                onPressed: () => _submit(data),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _title => switch (widget.mode) {
    EditorFormMode.create => 'New ${f.singularTitle}',
    EditorFormMode.edit => 'Edit ${f.singularTitle}',
    EditorFormMode.view => '${f.singularTitle} Details',
  };

  /// Starts from [data] so an update keeps the id and the fields that the form does not show.
  void _submit(${f.singularPascal}Entity? data) {
    final form = _formKey.currentState!;
    if (!form.saveAndValidate()) return;
    final entity = (data ?? const ${f.singularPascal}Entity()).copyWith(
      name: form.value['name'] as String?,
      description: form.value['description'] as String?,
    );
    context.read<${f.singularPascal}EditorBloc>().add(${f.singularPascal}EditorSubmit(entity));
  }
}
''');
}

// ---------------------------------------------------------------------------
// Mock Data
// ---------------------------------------------------------------------------

void _generateMockData(_FeatureNames f) {
  print('\nMock data:');

  // list(): GET with queryParams
  _writeFile('assets/mock/${_listMock(f)}', '''[
  {
    "id": "${f.singularKebab}-1",
    "name": "Sample ${f.singularTitle} 1",
    "description": "First sample ${f.singularTitle.toLowerCase()}",
    "createdDate": "2024-01-04T06:02:47.757Z",
    "lastModifiedDate": "2024-01-04T06:02:47.757Z"
  },
  {
    "id": "${f.singularKebab}-2",
    "name": "Sample ${f.singularTitle} 2",
    "description": "Second sample ${f.singularTitle.toLowerCase()}",
    "createdDate": "2024-01-05T08:15:30.000Z",
    "lastModifiedDate": "2024-01-05T08:15:30.000Z"
  }
]
''');

  // retrieve(): GET with pathParams
  _writeFile('assets/mock/${_retrieveMock(f)}', '''{
  "id": "${f.singularKebab}-1",
  "name": "Sample ${f.singularTitle} 1",
  "description": "First sample ${f.singularTitle.toLowerCase()}",
  "createdDate": "2024-01-04T06:02:47.757Z",
  "lastModifiedDate": "2024-01-04T06:02:47.757Z"
}
''');

  // create(): POST
  _writeFile('assets/mock/${_createMock(f)}', '''{
  "id": "${f.singularKebab}-new",
  "name": "New ${f.singularTitle}",
  "description": "Newly created ${f.singularTitle.toLowerCase()}",
  "createdDate": "2024-01-06T10:00:00.000Z",
  "lastModifiedDate": "2024-01-06T10:00:00.000Z"
}
''');

  // update(): PUT
  _writeFile('assets/mock/${_updateMock(f)}', '''{
  "id": "${f.singularKebab}-1",
  "name": "Updated ${f.singularTitle}",
  "description": "Updated ${f.singularTitle.toLowerCase()} description",
  "createdDate": "2024-01-04T06:02:47.757Z",
  "lastModifiedDate": "2024-01-07T12:00:00.000Z"
}
''');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void _generateTests(_FeatureNames f) {
  print('\nTests:');

  // List BLoC test
  _writeFile('test/features/${f.snake}/application/${f.singularSnake}_list_bloc_test.dart', '''
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_list_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/delete_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/list_${f.snake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockI${f.singularPascal}Repository extends Mock implements I${f.singularPascal}Repository {}

void main() {
  late MockI${f.singularPascal}Repository repository;

  setUp(() => repository = MockI${f.singularPascal}Repository());

  ${f.singularPascal}ListBloc buildBloc() => ${f.singularPascal}ListBloc(
    list${f.pascal}UseCase: List${f.pascal}UseCase(repository),
    delete${f.singularPascal}UseCase: Delete${f.singularPascal}UseCase(repository),
  );

  const items = [${f.singularPascal}Entity(id: '${f.singularKebab}-1', name: 'First'), ${f.singularPascal}Entity(id: '${f.singularKebab}-2', name: 'Second')];

  test('starts in ${f.singularPascal}ListInitial', () {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    expect(bloc.state, const ${f.singularPascal}ListInitial());
  });

  group('${f.singularPascal}ListLoad', () {
    blocTest<${f.singularPascal}ListBloc, ${f.singularPascal}ListState>(
      'emits [Loading, Loaded] with the listed items',
      setUp: () => when(() => repository.list(page: 0, size: 10)).thenAnswer((_) async => const Success(items)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ${f.singularPascal}ListLoad()),
      expect: () => const [${f.singularPascal}ListLoading(), ${f.singularPascal}ListLoaded(items: items)],
    );

    blocTest<${f.singularPascal}ListBloc, ${f.singularPascal}ListState>(
      'emits [Loading, Failure] when the list fails',
      setUp: () => when(
        () => repository.list(page: 0, size: 10),
      ).thenAnswer((_) async => const Failure(NetworkError('Connection failed'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const ${f.singularPascal}ListLoad()),
      expect: () => const [${f.singularPascal}ListLoading(), ${f.singularPascal}ListFailure(error: 'Connection failed')],
    );
  });

  group('${f.singularPascal}ListDelete', () {
    blocTest<${f.singularPascal}ListBloc, ${f.singularPascal}ListState>(
      'emits [Loading, DeleteSuccess] when the delete succeeds',
      setUp: () => when(() => repository.delete('${f.singularKebab}-1')).thenAnswer((_) async => const Success(null)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ${f.singularPascal}ListDelete('${f.singularKebab}-1')),
      expect: () => const [${f.singularPascal}ListLoading(), ${f.singularPascal}ListDeleteSuccess()],
    );

    blocTest<${f.singularPascal}ListBloc, ${f.singularPascal}ListState>(
      'emits [Loading, Failure] when the delete fails',
      setUp: () => when(
        () => repository.delete('${f.singularKebab}-1'),
      ).thenAnswer((_) async => const Failure(NetworkError('Connection failed'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const ${f.singularPascal}ListDelete('${f.singularKebab}-1')),
      expect: () => const [${f.singularPascal}ListLoading(), ${f.singularPascal}ListFailure(error: 'Connection failed')],
    );
  });
}
''');

  // Editor BLoC test
  _writeFile('test/features/${f.snake}/application/${f.singularSnake}_editor_bloc_test.dart', '''
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_editor_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/fetch_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/save_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockI${f.singularPascal}Repository extends Mock implements I${f.singularPascal}Repository {}

void main() {
  late MockI${f.singularPascal}Repository repository;

  setUp(() => repository = MockI${f.singularPascal}Repository());

  ${f.singularPascal}EditorBloc buildBloc() => ${f.singularPascal}EditorBloc(
    fetch${f.singularPascal}UseCase: Fetch${f.singularPascal}UseCase(repository),
    save${f.singularPascal}UseCase: Save${f.singularPascal}UseCase(repository),
  );

  const draft = ${f.singularPascal}Entity(name: 'First');
  const saved = ${f.singularPascal}Entity(id: '${f.singularKebab}-1', name: 'First');

  test('starts in ${f.singularPascal}EditorInitial', () {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    expect(bloc.state, const ${f.singularPascal}EditorInitial());
  });

  group('${f.singularPascal}EditorFetch', () {
    blocTest<${f.singularPascal}EditorBloc, ${f.singularPascal}EditorState>(
      'emits [Loading, Loaded] with the fetched item',
      setUp: () => when(() => repository.retrieve('${f.singularKebab}-1')).thenAnswer((_) async => const Success(saved)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ${f.singularPascal}EditorFetch('${f.singularKebab}-1')),
      expect: () => const [${f.singularPascal}EditorLoading(), ${f.singularPascal}EditorLoaded(data: saved)],
    );

    blocTest<${f.singularPascal}EditorBloc, ${f.singularPascal}EditorState>(
      'emits [Loading, LoadFailure] when the fetch fails',
      setUp: () => when(
        () => repository.retrieve('${f.singularKebab}-1'),
      ).thenAnswer((_) async => const Failure(NotFoundError('Not found'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const ${f.singularPascal}EditorFetch('${f.singularKebab}-1')),
      expect: () => const [${f.singularPascal}EditorLoading(), ${f.singularPascal}EditorLoadFailure(error: 'Not found')],
    );
  });

  group('${f.singularPascal}EditorSubmit', () {
    blocTest<${f.singularPascal}EditorBloc, ${f.singularPascal}EditorState>(
      'creates an item without an id and emits [Saving, Saved]',
      setUp: () => when(() => repository.create(draft)).thenAnswer((_) async => const Success(saved)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ${f.singularPascal}EditorSubmit(draft)),
      expect: () => const [${f.singularPascal}EditorSaving(data: draft), ${f.singularPascal}EditorSaved(data: saved)],
      verify: (_) => verify(() => repository.create(draft)).called(1),
    );

    blocTest<${f.singularPascal}EditorBloc, ${f.singularPascal}EditorState>(
      'updates an item with an id and emits [Saving, Saved]',
      setUp: () => when(() => repository.update(saved)).thenAnswer((_) async => const Success(saved)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ${f.singularPascal}EditorSubmit(saved)),
      expect: () => const [${f.singularPascal}EditorSaving(data: saved), ${f.singularPascal}EditorSaved(data: saved)],
      verify: (_) => verify(() => repository.update(saved)).called(1),
    );

    blocTest<${f.singularPascal}EditorBloc, ${f.singularPascal}EditorState>(
      'emits [Saving, SaveFailure] that keeps the submitted item when the save fails',
      setUp: () => when(
        () => repository.create(draft),
      ).thenAnswer((_) async => const Failure(ValidationError('Name is taken'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const ${f.singularPascal}EditorSubmit(draft)),
      expect: () => const [
        ${f.singularPascal}EditorSaving(data: draft),
        ${f.singularPascal}EditorSaveFailure(error: 'Name is taken', data: draft),
      ],
    );
  });
}
''');

  // Model test
  _writeFile('test/features/${f.snake}/data/models/${f.singularSnake}_model_test.dart', '''
import 'dart:convert';

import 'package:flutter_bloc_advance/features/${f.snake}/data/models/${f.singularSnake}_model.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const json = <String, dynamic>{
    'id': '${f.singularKebab}-1',
    'name': 'First',
    'description': 'The first item',
    'createdDate': '2024-01-04T06:02:47.757Z',
    'lastModifiedDate': '2024-01-05T08:15:30.000Z',
  };

  test('fromJson reads every field', () {
    final model = ${f.singularPascal}Model.fromJson(json);

    expect(model.id, '${f.singularKebab}-1');
    expect(model.name, 'First');
    expect(model.description, 'The first item');
    expect(model.createdDate, DateTime.utc(2024, 1, 4, 6, 2, 47, 757));
    expect(model.lastModifiedDate, DateTime.utc(2024, 1, 5, 8, 15, 30));
  });

  test('toJson writes what fromJson reads', () {
    expect(${f.singularPascal}Model.fromJson(json).toJson(), json);
  });

  test('toJson leaves out empty fields', () {
    expect(const ${f.singularPascal}Model(name: 'Draft').toJson(), {'name': 'Draft'});
  });

  test('fromJsonStringList reads a JSON array', () {
    final models = ${f.singularPascal}Model.fromJsonStringList(jsonEncode([json, json]));

    expect(models.map((model) => model.id), ['${f.singularKebab}-1', '${f.singularKebab}-1']);
  });

  test('fromEntity copies every field', () {
    final entity = ${f.singularPascal}Entity(
      id: '${f.singularKebab}-1',
      name: 'First',
      description: 'The first item',
      createdDate: DateTime.utc(2024, 1, 4),
      lastModifiedDate: DateTime.utc(2024, 1, 5),
    );

    expect(${f.singularPascal}Model.fromEntity(entity).props, entity.props);
  });
}
''');

  // Repository test, through the real ApiClient chain
  _writeFile('test/features/${f.snake}/data/repositories/${f.singularSnake}_repository_test.dart', '''
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/data/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_env.dart';

/// Sends each request through the real ApiClient chain, where MockInterceptor answers from assets/mock/. A mock file
/// whose name does not match the request is never served, so these tests catch a naming drift.
void main() {
  late ${f.singularPascal}Repository repository;

  setUp(() => repository = ${f.singularPascal}Repository(TestEnv.apiClient()));

  test('list is served ${_listMock(f)}', () async {
    TestEnv.authenticate();

    final result = await repository.list();

    expect(
      result,
      isA<Success<List<${f.singularPascal}Entity>>>().having(
        (success) => success.data.map((item) => item.name).toList(),
        'names',
        ['Sample ${f.singularTitle} 1', 'Sample ${f.singularTitle} 2'],
      ),
    );
  });

  test('retrieve is served ${_retrieveMock(f)}', () async {
    TestEnv.authenticate();

    final result = await repository.retrieve('${f.singularKebab}-1');

    expect(result, isA<Success<${f.singularPascal}Entity>>().having((success) => success.data.name, 'name', 'Sample ${f.singularTitle} 1'));
  });

  test('create is served ${_createMock(f)}', () async {
    TestEnv.authenticate();

    final result = await repository.create(const ${f.singularPascal}Entity(name: 'New ${f.singularTitle}'));

    expect(result, isA<Success<${f.singularPascal}Entity>>().having((success) => success.data.id, 'id', '${f.singularKebab}-new'));
  });

  test('update is served ${_updateMock(f)}', () async {
    TestEnv.authenticate();

    final result = await repository.update(const ${f.singularPascal}Entity(id: '${f.singularKebab}-1', name: 'Renamed'));

    expect(
      result,
      isA<Success<${f.singularPascal}Entity>>().having((success) => success.data.name, 'name', 'Updated ${f.singularTitle}'),
    );
  });

  test('delete succeeds without a mock file', () async {
    TestEnv.authenticate();

    expect(await repository.delete('${f.singularKebab}-1'), isA<Success<void>>());
  });

  test('list fails with an AuthError without a session', () async {
    final result = await repository.list();

    expect(result, isA<Failure<List<${f.singularPascal}Entity>>>().having((failure) => failure.error, 'error', isA<AuthError>()));
  });
}
''');

  // Route test: the whole feature, the way it runs in dev mode
  _writeFile('test/features/${f.snake}/navigation/${f.snake}_routes_test.dart', '''
@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/data/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/navigation/${f.snake}_routes.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/test_env.dart';

/// Drives the routes through the real BLoCs, use cases, repository and ApiClient, with MockInterceptor answering
/// from assets/mock/: the feature the way it runs in dev mode.
void main() {
  Widget buildApp(String location) {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        // The app shell gives every feature page a Scaffold.
        ShellRoute(builder: (context, state, child) => Scaffold(body: child), routes: ${f.pascal}FeatureRoutes.routes),
      ],
    );
    return RepositoryProvider<I${f.singularPascal}Repository>(
      create: (_) => ${f.singularPascal}Repository(TestEnv.apiClient()),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    );
  }

  setUp(TestEnv.authenticate);
  // rootBundle caches each loaded mock file as a future of the test that loaded it. A later test awaiting that
  // future never resumes, because the earlier test's fake async zone no longer runs, so start every test uncached.
  setUp(rootBundle.clear);

  testWidgets('the list route shows the items from the mock API', (tester) async {
    await tester.pumpWidget(buildApp('/${f.kebab}'));
    await tester.pumpAndSettle();

    expect(find.text('Sample ${f.singularTitle} 1'), findsOneWidget);
    expect(find.text('Sample ${f.singularTitle} 2'), findsOneWidget);
  });

  testWidgets('the view route shows the item from the mock API', (tester) async {
    await tester.pumpWidget(buildApp('/${f.kebab}/${f.singularKebab}-1/view'));
    await tester.pumpAndSettle();

    expect(find.text('Sample ${f.singularTitle} 1'), findsOneWidget);
    expect(find.byKey(const Key('${f.singularCamel}EditorSubmitButtonKey')), findsNothing);
  });

  testWidgets('saving the create form returns to the list', (tester) async {
    await tester.pumpWidget(buildApp('/${f.kebab}/new'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('${f.singularCamel}EditorNameFieldKey')), 'Brand new item');
    await tester.tap(find.byKey(const Key('${f.singularCamel}EditorSubmitButtonKey')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('${f.singularCamel}ListCreateButtonKey')), findsOneWidget);
    expect(find.text('Sample ${f.singularTitle} 1'), findsOneWidget);
  });

  testWidgets('the create form does not submit without a name', (tester) async {
    await tester.pumpWidget(buildApp('/${f.kebab}/new'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('${f.singularCamel}EditorSubmitButtonKey')));
    await tester.pumpAndSettle();

    expect(find.text(S.current.required_field), findsOneWidget);
    expect(find.byKey(const Key('${f.singularCamel}ListCreateButtonKey')), findsNothing);
  });
}
''');
}

// ---------------------------------------------------------------------------
// Barrel Export
// ---------------------------------------------------------------------------

void _generateBarrelExport(_FeatureNames f) {
  print('\nBarrel export:');

  _writeFile('lib/features/${f.snake}/${f.snake}.dart', '''
/// ${f.title} feature: public API.
library;

export 'application/${f.singularSnake}_editor_bloc.dart';
export 'application/${f.singularSnake}_list_bloc.dart';
export 'domain/entities/${f.singularSnake}_entity.dart';
export 'domain/repositories/${f.singularSnake}_repository.dart';
export 'navigation/${f.snake}_routes.dart';
''');
}
