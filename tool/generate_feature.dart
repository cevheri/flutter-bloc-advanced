#!/usr/bin/env dart
// ignore_for_file: avoid_print

// Feature Scaffolding CLI — generates a complete feature skeleton.
//
// Usage:
//   dart run tool/generate_feature.dart <feature_name>
//
// Example:
//   dart run tool/generate_feature.dart orders
//
// Generates:
//   lib/features/{feature}/  (domain, data, application, navigation, presentation)
//   test/features/{feature}/  (application, data, presentation)
//   assets/mock/              (GET, POST, PUT mock JSON files)
//
// After generation, follow the printed instructions to register routes,
// DI, and localization entries.
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/generate_feature.dart <feature_name>');
    print('Example: dart run tool/generate_feature.dart orders');
    exit(1);
  }

  final rawName = args[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  final feature = _FeatureNames(rawName);

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

  print('');
  print('=' * 60);
  print('Feature "${feature.snake}" generated successfully!');
  print('');
  print('NEXT STEPS:');
  print('');
  print('1. Register routes in lib/app/router/app_router.dart:');
  print(
    '   import \'package:flutter_bloc_advance/features/${feature.snake}/navigation/${feature.snake}_routes.dart\';',
  );
  print('   // Add inside ShellRoute.routes:');
  print('   ...${feature.pascal}FeatureRoutes.routes,');
  print('');
  print('2. Register route constants in lib/app/router/app_routes_constants.dart:');
  print('   static const ${feature.camel}List = \'/${feature.kebab}\';');
  print('   static const ${feature.camel}View = \'/${feature.kebab}/:id/view\';');
  print('   static const ${feature.camel}Edit = \'/${feature.kebab}/:id/edit\';');
  print('   static const ${feature.camel}New = \'/${feature.kebab}/new\';');
  print('');
  print('3. Register repository in lib/app/di/app_dependencies.dart:');
  print('   I${feature.pascal}Repository create${feature.pascal}Repository() {');
  print('     return ${feature.pascal}Repository();');
  print('   }');
  print('');
  print('4. Register in lib/app/di/app_scope.dart:');
  print(
    '   RepositoryProvider<I${feature.pascal}Repository>(create: (_) => dependencies.create${feature.pascal}Repository()),',
  );
  print('');
  print('5. Add menu entry for sidebar navigation.');
  print('');
  print('6. Add translations to lib/l10n/intl_en.arb and run:');
  print('   fvm dart run intl_utils:generate');
  print('');
}

// ---------------------------------------------------------------------------
// Name utilities
// ---------------------------------------------------------------------------

class _FeatureNames {
  _FeatureNames(this.snake);

  final String snake; // orders

  String get pascal => _toPascal(snake); // Orders
  String get camel => _toCamel(snake); // orders
  String get kebab => snake.replaceAll('_', '-'); // orders

  String get entityName => '${pascal}Entity'; // OrdersEntity → but singular: OrderEntity
  String get singularSnake => _singularize(snake); // order
  String get singularPascal => _toPascal(singularSnake); // Order
  String get singularCamel => _toCamel(singularSnake); // order
  String get modelName => singularPascal; // Order
}

String _toPascal(String snake) {
  return snake.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join();
}

String _toCamel(String snake) {
  final pascal = _toPascal(snake);
  if (pascal.isEmpty) return pascal;
  return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
}

String _singularize(String word) {
  if (word.endsWith('ies')) return '${word.substring(0, word.length - 3)}y';
  if (word.endsWith('ses') || word.endsWith('xes') || word.endsWith('zes')) return word.substring(0, word.length - 2);
  if (word.endsWith('s') && !word.endsWith('ss')) return word.substring(0, word.length - 1);
  return word;
}

// ---------------------------------------------------------------------------
// File generation
// ---------------------------------------------------------------------------

void _writeFile(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  print('  Created: $path');
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
  const ${f.singularPascal}Entity({
    this.id,
    this.name,
    this.description,
    this.createdDate,
    this.lastModifiedDate,
  });

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
  const ${f.singularPascal}Model({
    super.id,
    super.name,
    super.description,
    super.createdDate,
    super.lastModifiedDate,
  });

  factory ${f.singularPascal}Model.fromEntity(${f.singularPascal}Entity entity) {
    return ${f.singularPascal}Model(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      createdDate: entity.createdDate,
      lastModifiedDate: entity.lastModifiedDate,
    );
  }

  static ${f.singularPascal}Model? fromJson(Map<String, dynamic> json) {
    return ${f.singularPascal}Model(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      createdDate: json['createdDate'] != null ? DateTime.tryParse(json['createdDate'] as String) : null,
      lastModifiedDate: json['lastModifiedDate'] != null ? DateTime.tryParse(json['lastModifiedDate'] as String) : null,
    );
  }

  static ${f.singularPascal}Model? fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return fromJson(json as Map<String, dynamic>);
  }

  static List<${f.singularPascal}Model> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => fromJson(e as Map<String, dynamic>)).whereType<${f.singularPascal}Model>().toList();
  }

  static List<${f.singularPascal}Model> fromJsonStringList(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return fromJsonList(list);
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
      if (lastModifiedDate != null) 'lastModifiedDate': lastModifiedDate!.toIso8601String(),
    };
  }

  @override
  bool get stringify => true;
}
''');

  // Repository implementation
  _writeFile('lib/features/${f.snake}/data/repositories/${f.singularSnake}_repository.dart', '''
import 'dart:convert';

import 'package:flutter_bloc_advance/core/errors/app_api_exception.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/data/models/${f.singularSnake}_model.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';

class ${f.singularPascal}Repository implements I${f.singularPascal}Repository {
  static final _log = AppLogger.getLogger('${f.singularPascal}Repository');
  static const String _resource = '${f.snake}';

  @override
  Future<Result<${f.singularPascal}Entity>> retrieve(String id) async {
    _log.debug('Retrieving ${f.singularSnake}: {}', [id]);
    try {
      final response = await ApiClient.get('/\$_resource', pathParams: id);
      final model = ${f.singularPascal}Model.fromJsonString(response.data!);
      if (model == null) return const Failure(UnknownError('Failed to parse response'));
      return Success(model);
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<${f.singularPascal}Entity>> create(${f.singularPascal}Entity entity) async {
    _log.debug('Creating ${f.singularSnake}');
    try {
      final model = ${f.singularPascal}Model.fromEntity(entity);
      final response = await ApiClient.post('/\$_resource', model.toJson());
      final result = ${f.singularPascal}Model.fromJsonString(response.data!);
      if (result == null) return const Failure(UnknownError('Failed to parse response'));
      return Success(result);
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<${f.singularPascal}Entity>> update(${f.singularPascal}Entity entity) async {
    _log.debug('Updating ${f.singularSnake}: {}', [entity.id]);
    try {
      final model = ${f.singularPascal}Model.fromEntity(entity);
      final response = await ApiClient.put('/\$_resource', model.toJson());
      final result = ${f.singularPascal}Model.fromJsonString(response.data!);
      if (result == null) return const Failure(UnknownError('Failed to parse response'));
      return Success(result);
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on BadRequestException catch (e) {
      return Failure(ValidationError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<${f.singularPascal}Entity>>> list({int page = 0, int size = 10}) async {
    _log.debug('Listing ${f.snake}: page={}, size={}', [page, size]);
    try {
      final response = await ApiClient.get(
        '/\$_resource',
        queryParams: {'page': page.toString(), 'size': size.toString()},
      );
      final list = jsonDecode(response.data!) as List<dynamic>;
      final models = ${f.singularPascal}Model.fromJsonList(list);
      return Success(models);
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    _log.debug('Deleting ${f.singularSnake}: {}', [id]);
    try {
      await ApiClient.delete('/\$_resource', pathParams: id);
      return const Success(null);
    } on UnauthorizedException catch (e) {
      return Failure(AuthError(e.toString()));
    } on FetchDataException catch (e) {
      return Failure(_mapFetchDataException(e));
    } catch (e) {
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

  // Events
  _writeFile('lib/features/${f.snake}/application/${f.singularSnake}_event.dart', '''
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';

class ${f.singularPascal}Event extends Equatable {
  const ${f.singularPascal}Event();
  @override
  List<Object> get props => [];
}

class ${f.singularPascal}ListEvent extends ${f.singularPascal}Event {
  const ${f.singularPascal}ListEvent({this.page = 0, this.size = 10});
  final int page;
  final int size;
}

class ${f.singularPascal}FetchEvent extends ${f.singularPascal}Event {
  const ${f.singularPascal}FetchEvent(this.id);
  final String id;
  @override
  List<Object> get props => [id];
}

class ${f.singularPascal}CreateEvent extends ${f.singularPascal}Event {
  const ${f.singularPascal}CreateEvent(this.entity);
  final ${f.singularPascal}Entity entity;
  @override
  List<Object> get props => [entity];
}

class ${f.singularPascal}UpdateEvent extends ${f.singularPascal}Event {
  const ${f.singularPascal}UpdateEvent(this.entity);
  final ${f.singularPascal}Entity entity;
  @override
  List<Object> get props => [entity];
}

class ${f.singularPascal}DeleteEvent extends ${f.singularPascal}Event {
  const ${f.singularPascal}DeleteEvent(this.id);
  final String id;
  @override
  List<Object> get props => [id];
}

class ${f.singularPascal}EditorInitEvent extends ${f.singularPascal}Event {
  const ${f.singularPascal}EditorInitEvent();
}

class ${f.singularPascal}SaveCompleteEvent extends ${f.singularPascal}Event {
  const ${f.singularPascal}SaveCompleteEvent();
}
''');

  // States
  _writeFile('lib/features/${f.snake}/application/${f.singularSnake}_state.dart', '''
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';

enum ${f.singularPascal}Status {
  initial,
  loading,
  success,
  failure,
  listSuccess,
  fetchSuccess,
  createSuccess,
  updateSuccess,
  deleteSuccess,
}

class ${f.singularPascal}State extends Equatable {
  const ${f.singularPascal}State({
    this.status = ${f.singularPascal}Status.initial,
    this.data,
    this.dataList,
    this.error,
  });

  final ${f.singularPascal}Status status;
  final ${f.singularPascal}Entity? data;
  final List<${f.singularPascal}Entity>? dataList;
  final String? error;

  ${f.singularPascal}State copyWith({
    ${f.singularPascal}Status? status,
    ${f.singularPascal}Entity? data,
    List<${f.singularPascal}Entity>? dataList,
    String? error,
  }) {
    return ${f.singularPascal}State(
      status: status ?? this.status,
      data: data ?? this.data,
      dataList: dataList ?? this.dataList,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, data, dataList, error];
}
''');

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

  // BLoC
  _writeFile('lib/features/${f.snake}/application/${f.singularSnake}_bloc.dart', '''
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_event.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_state.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/list_${f.snake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/fetch_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/save_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/delete_${f.singularSnake}_usecase.dart';

class ${f.singularPascal}Bloc extends Bloc<${f.singularPascal}Event, ${f.singularPascal}State> {
  ${f.singularPascal}Bloc({
    required List${f.pascal}UseCase list${f.pascal}UseCase,
    required Fetch${f.singularPascal}UseCase fetch${f.singularPascal}UseCase,
    required Save${f.singularPascal}UseCase save${f.singularPascal}UseCase,
    required Delete${f.singularPascal}UseCase delete${f.singularPascal}UseCase,
  })  : _list${f.pascal}UseCase = list${f.pascal}UseCase,
        _fetch${f.singularPascal}UseCase = fetch${f.singularPascal}UseCase,
        _save${f.singularPascal}UseCase = save${f.singularPascal}UseCase,
        _delete${f.singularPascal}UseCase = delete${f.singularPascal}UseCase,
        super(const ${f.singularPascal}State()) {
    on<${f.singularPascal}ListEvent>(_onList);
    on<${f.singularPascal}FetchEvent>(_onFetch);
    on<${f.singularPascal}CreateEvent>(_onCreate);
    on<${f.singularPascal}UpdateEvent>(_onUpdate);
    on<${f.singularPascal}DeleteEvent>(_onDelete);
    on<${f.singularPascal}EditorInitEvent>(_onEditorInit);
    on<${f.singularPascal}SaveCompleteEvent>(_onSaveComplete);
  }

  static final _log = AppLogger.getLogger('${f.singularPascal}Bloc');

  final List${f.pascal}UseCase _list${f.pascal}UseCase;
  final Fetch${f.singularPascal}UseCase _fetch${f.singularPascal}UseCase;
  final Save${f.singularPascal}UseCase _save${f.singularPascal}UseCase;
  final Delete${f.singularPascal}UseCase _delete${f.singularPascal}UseCase;

  FutureOr<void> _onList(${f.singularPascal}ListEvent event, Emitter<${f.singularPascal}State> emit) async {
    _log.debug('Listing ${f.snake}: page={}, size={}', [event.page, event.size]);
    emit(state.copyWith(status: ${f.singularPascal}Status.loading));
    final result = await _list${f.pascal}UseCase(page: event.page, size: event.size);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: ${f.singularPascal}Status.listSuccess, dataList: data));
      case Failure(:final error):
        emit(state.copyWith(status: ${f.singularPascal}Status.failure, error: error.message));
    }
  }

  FutureOr<void> _onFetch(${f.singularPascal}FetchEvent event, Emitter<${f.singularPascal}State> emit) async {
    _log.debug('Fetching ${f.singularSnake}: {}', [event.id]);
    emit(state.copyWith(status: ${f.singularPascal}Status.loading));
    final result = await _fetch${f.singularPascal}UseCase(event.id);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: ${f.singularPascal}Status.fetchSuccess, data: data));
      case Failure(:final error):
        emit(state.copyWith(status: ${f.singularPascal}Status.failure, error: error.message));
    }
  }

  FutureOr<void> _onCreate(${f.singularPascal}CreateEvent event, Emitter<${f.singularPascal}State> emit) async {
    _log.debug('Creating ${f.singularSnake}');
    emit(state.copyWith(status: ${f.singularPascal}Status.loading));
    final result = await _save${f.singularPascal}UseCase(event.entity);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: ${f.singularPascal}Status.createSuccess, data: data));
      case Failure(:final error):
        emit(state.copyWith(status: ${f.singularPascal}Status.failure, error: error.message));
    }
  }

  FutureOr<void> _onUpdate(${f.singularPascal}UpdateEvent event, Emitter<${f.singularPascal}State> emit) async {
    _log.debug('Updating ${f.singularSnake}: {}', [event.entity.id]);
    emit(state.copyWith(status: ${f.singularPascal}Status.loading));
    final result = await _save${f.singularPascal}UseCase(event.entity);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: ${f.singularPascal}Status.updateSuccess, data: data));
      case Failure(:final error):
        emit(state.copyWith(status: ${f.singularPascal}Status.failure, error: error.message));
    }
  }

  FutureOr<void> _onDelete(${f.singularPascal}DeleteEvent event, Emitter<${f.singularPascal}State> emit) async {
    _log.debug('Deleting ${f.singularSnake}: {}', [event.id]);
    emit(state.copyWith(status: ${f.singularPascal}Status.loading));
    final result = await _delete${f.singularPascal}UseCase(event.id);
    switch (result) {
      case Success():
        emit(state.copyWith(status: ${f.singularPascal}Status.deleteSuccess));
      case Failure(:final error):
        emit(state.copyWith(status: ${f.singularPascal}Status.failure, error: error.message));
    }
  }

  FutureOr<void> _onEditorInit(${f.singularPascal}EditorInitEvent event, Emitter<${f.singularPascal}State> emit) {
    emit(const ${f.singularPascal}State());
  }

  FutureOr<void> _onSaveComplete(${f.singularPascal}SaveCompleteEvent event, Emitter<${f.singularPascal}State> emit) {
    emit(state.copyWith(status: ${f.singularPascal}Status.initial));
  }
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
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/list_${f.snake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/fetch_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/save_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/delete_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/presentation/pages/${f.singularSnake}_list_page.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/presentation/pages/${f.singularSnake}_editor_page.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/shared/widgets/editor_form_mode.dart';
import 'package:go_router/go_router.dart';

class ${f.pascal}FeatureRoutes {
  static Widget _withBloc(BuildContext context, Widget child) {
    final repo = context.read<I${f.singularPascal}Repository>();
    return BlocProvider(
      create: (_) => ${f.singularPascal}Bloc(
        list${f.pascal}UseCase: List${f.pascal}UseCase(repo),
        fetch${f.singularPascal}UseCase: Fetch${f.singularPascal}UseCase(repo),
        save${f.singularPascal}UseCase: Save${f.singularPascal}UseCase(repo),
        delete${f.singularPascal}UseCase: Delete${f.singularPascal}UseCase(repo),
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
        child: _withBloc(context, const ${f.singularPascal}ListPage()),
      ),
    ),
    GoRoute(
      name: '${f.camel}Create',
      path: '/${f.kebab}/new',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withBloc(context, const ${f.singularPascal}EditorPage(mode: EditorFormMode.create)),
      ),
    ),
    GoRoute(
      name: '${f.camel}Edit',
      path: '/${f.kebab}/:id/edit',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withBloc(context, ${f.singularPascal}EditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.edit)),
      ),
    ),
    GoRoute(
      name: '${f.camel}View',
      path: '/${f.kebab}/:id/view',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: _withBloc(context, ${f.singularPascal}EditorPage(id: state.pathParameters['id']!, mode: EditorFormMode.view)),
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
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_event.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_empty_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
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
    context.read<${f.singularPascal}Bloc>().add(const ${f.singularPascal}ListEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${f.pascal}', style: Theme.of(context).textTheme.headlineSmall),
              AppButton(
                label: 'New ${f.singularPascal}',
                icon: Icons.add,
                onPressed: () => context.go('/${f.kebab}/new'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: BlocBuilder<${f.singularPascal}Bloc, ${f.singularPascal}State>(
              builder: (context, state) {
                if (state.status == ${f.singularPascal}Status.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == ${f.singularPascal}Status.failure) {
                  return AppErrorState(
                    title: 'Error',
                    message: state.error ?? 'An error occurred',
                    onRetry: () => context.read<${f.singularPascal}Bloc>().add(const ${f.singularPascal}ListEvent()),
                  );
                }
                final items = state.dataList ?? [];
                if (items.isEmpty) {
                  return const AppEmptyState(
                    title: 'No ${f.pascal}',
                    message: 'No ${f.snake} found. Create one to get started.',
                    icon: Icons.inbox_outlined,
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.name ?? 'Unnamed'),
                      subtitle: Text(item.description ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/${f.kebab}/\${item.id}/view'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
''');

  // Editor page
  _writeFile('lib/features/${f.snake}/presentation/pages/${f.singularSnake}_editor_page.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_event.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_state.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/widgets/editor_form_mode.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

class ${f.singularPascal}EditorPage extends StatefulWidget {
  const ${f.singularPascal}EditorPage({super.key, this.id, required this.mode});

  final String? id;
  final EditorFormMode mode;

  @override
  State<${f.singularPascal}EditorPage> createState() => _${f.singularPascal}EditorPageState();
}

class _${f.singularPascal}EditorPageState extends State<${f.singularPascal}EditorPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      context.read<${f.singularPascal}Bloc>().add(${f.singularPascal}FetchEvent(widget.id!));
    } else {
      context.read<${f.singularPascal}Bloc>().add(const ${f.singularPascal}EditorInitEvent());
    }
  }

  bool get _isReadOnly => widget.mode == EditorFormMode.view;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<${f.singularPascal}Bloc, ${f.singularPascal}State>(
      listener: (context, state) {
        if (state.status == ${f.singularPascal}Status.createSuccess || state.status == ${f.singularPascal}Status.updateSuccess) {
          context.go('/${f.kebab}');
        }
      },
      builder: (context, state) {
        if (state.status == ${f.singularPascal}Status.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mode == EditorFormMode.create ? 'New ${f.singularPascal}' : '${f.singularPascal} Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                FormBuilderTextField(
                  name: 'name',
                  initialValue: state.data?.name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  readOnly: _isReadOnly,
                  validator: FormBuilderValidators.compose([FormBuilderValidators.required()]),
                ),
                const SizedBox(height: AppSpacing.lg),
                FormBuilderTextField(
                  name: 'description',
                  initialValue: state.data?.description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  readOnly: _isReadOnly,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!_isReadOnly)
                  AppButton(
                    label: widget.mode == EditorFormMode.create ? 'Create' : 'Save',
                    onPressed: _onSubmit,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final entity = ${f.singularPascal}Entity(
        id: widget.id,
        name: values['name'] as String?,
        description: values['description'] as String?,
      );
      if (widget.mode == EditorFormMode.create) {
        context.read<${f.singularPascal}Bloc>().add(${f.singularPascal}CreateEvent(entity));
      } else {
        context.read<${f.singularPascal}Bloc>().add(${f.singularPascal}UpdateEvent(entity));
      }
    }
  }
}
''');
}

// ---------------------------------------------------------------------------
// Mock Data
// ---------------------------------------------------------------------------

void _generateMockData(_FeatureNames f) {
  print('\nMock data:');

  // GET list
  _writeFile('assets/mock/GET_${f.snake}.json', '''[
  {
    "id": "${f.singularSnake}-1",
    "name": "Sample ${f.singularPascal} 1",
    "description": "First sample ${f.singularSnake}",
    "createdDate": "2024-01-04T06:02:47.757Z",
    "lastModifiedDate": "2024-01-04T06:02:47.757Z"
  },
  {
    "id": "${f.singularSnake}-2",
    "name": "Sample ${f.singularPascal} 2",
    "description": "Second sample ${f.singularSnake}",
    "createdDate": "2024-01-05T08:15:30.000Z",
    "lastModifiedDate": "2024-01-05T08:15:30.000Z"
  }
]
''');

  // GET by id
  _writeFile('assets/mock/GET_${f.snake}_pathParams.json', '''{
  "id": "${f.singularSnake}-1",
  "name": "Sample ${f.singularPascal} 1",
  "description": "First sample ${f.singularSnake}",
  "createdDate": "2024-01-04T06:02:47.757Z",
  "lastModifiedDate": "2024-01-04T06:02:47.757Z"
}
''');

  // POST
  _writeFile('assets/mock/POST_${f.snake}.json', '''{
  "id": "${f.singularSnake}-new",
  "name": "New ${f.singularPascal}",
  "description": "Newly created ${f.singularSnake}",
  "createdDate": "2024-01-06T10:00:00.000Z",
  "lastModifiedDate": "2024-01-06T10:00:00.000Z"
}
''');

  // PUT
  _writeFile('assets/mock/PUT_${f.snake}.json', '''{
  "id": "${f.singularSnake}-1",
  "name": "Updated ${f.singularPascal}",
  "description": "Updated ${f.singularSnake} description",
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

  // BLoC test
  _writeFile('test/features/${f.snake}/application/${f.singularSnake}_bloc_test.dart', '''
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_bloc.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_event.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/${f.singularSnake}_state.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/list_${f.snake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/fetch_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/save_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/application/usecases/delete_${f.singularSnake}_usecase.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/entities/${f.singularSnake}_entity.dart';
import 'package:flutter_bloc_advance/features/${f.snake}/domain/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements I${f.singularPascal}Repository {}

void main() {
  late MockRepository mockRepository;
  late ${f.singularPascal}Bloc bloc;

  setUp(() {
    mockRepository = MockRepository();
    bloc = ${f.singularPascal}Bloc(
      list${f.pascal}UseCase: List${f.pascal}UseCase(mockRepository),
      fetch${f.singularPascal}UseCase: Fetch${f.singularPascal}UseCase(mockRepository),
      save${f.singularPascal}UseCase: Save${f.singularPascal}UseCase(mockRepository),
      delete${f.singularPascal}UseCase: Delete${f.singularPascal}UseCase(mockRepository),
    );
  });

  tearDown(() => bloc.close());

  group('${f.singularPascal}Bloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const ${f.singularPascal}State());
      expect(bloc.state.status, ${f.singularPascal}Status.initial);
    });

    group('list', () {
      final testEntities = [
        const ${f.singularPascal}Entity(id: '1', name: 'Test 1'),
        const ${f.singularPascal}Entity(id: '2', name: 'Test 2'),
      ];

      blocTest<${f.singularPascal}Bloc, ${f.singularPascal}State>(
        'emits [loading, listSuccess] when list succeeds',
        build: () {
          when(() => mockRepository.list(page: 0, size: 10)).thenAnswer((_) async => Success(testEntities));
          return bloc;
        },
        act: (bloc) => bloc.add(const ${f.singularPascal}ListEvent()),
        expect: () => [
          const ${f.singularPascal}State(status: ${f.singularPascal}Status.loading),
          ${f.singularPascal}State(status: ${f.singularPascal}Status.listSuccess, dataList: testEntities),
        ],
      );

      blocTest<${f.singularPascal}Bloc, ${f.singularPascal}State>(
        'emits [loading, failure] when list fails',
        build: () {
          when(() => mockRepository.list(page: 0, size: 10))
              .thenAnswer((_) async => const Failure(NetworkError('Connection failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(const ${f.singularPascal}ListEvent()),
        expect: () => [
          const ${f.singularPascal}State(status: ${f.singularPascal}Status.loading),
          const ${f.singularPascal}State(status: ${f.singularPascal}Status.failure, error: 'Connection failed'),
        ],
      );
    });

    group('fetch', () {
      const testEntity = ${f.singularPascal}Entity(id: '1', name: 'Test');

      blocTest<${f.singularPascal}Bloc, ${f.singularPascal}State>(
        'emits [loading, fetchSuccess] when fetch succeeds',
        build: () {
          when(() => mockRepository.retrieve('1')).thenAnswer((_) async => const Success(testEntity));
          return bloc;
        },
        act: (bloc) => bloc.add(const ${f.singularPascal}FetchEvent('1')),
        expect: () => [
          const ${f.singularPascal}State(status: ${f.singularPascal}Status.loading),
          const ${f.singularPascal}State(status: ${f.singularPascal}Status.fetchSuccess, data: testEntity),
        ],
      );
    });

    group('delete', () {
      blocTest<${f.singularPascal}Bloc, ${f.singularPascal}State>(
        'emits [loading, deleteSuccess] when delete succeeds',
        build: () {
          when(() => mockRepository.delete('1')).thenAnswer((_) async => const Success(null));
          return bloc;
        },
        act: (bloc) => bloc.add(const ${f.singularPascal}DeleteEvent('1')),
        expect: () => [
          const ${f.singularPascal}State(status: ${f.singularPascal}Status.loading),
          const ${f.singularPascal}State(status: ${f.singularPascal}Status.deleteSuccess),
        ],
      );
    });
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
  group('${f.singularPascal}Model', () {
    const testJson = {
      'id': 'test-1',
      'name': 'Test ${f.singularPascal}',
      'description': 'A test ${f.singularSnake}',
      'createdDate': '2024-01-04T06:02:47.757Z',
      'lastModifiedDate': '2024-01-04T06:02:47.757Z',
    };

    test('fromJson creates valid model', () {
      final model = ${f.singularPascal}Model.fromJson(testJson);
      expect(model, isNotNull);
      expect(model!.id, 'test-1');
      expect(model.name, 'Test ${f.singularPascal}');
      expect(model.description, 'A test ${f.singularSnake}');
    });

    test('fromJsonString creates valid model', () {
      final model = ${f.singularPascal}Model.fromJsonString(jsonEncode(testJson));
      expect(model, isNotNull);
      expect(model!.id, 'test-1');
    });

    test('fromJsonList creates valid list', () {
      final list = ${f.singularPascal}Model.fromJsonList([testJson, testJson]);
      expect(list.length, 2);
    });

    test('toJson produces valid map', () {
      final model = ${f.singularPascal}Model.fromJson(testJson);
      final json = model!.toJson();
      expect(json['id'], 'test-1');
      expect(json['name'], 'Test ${f.singularPascal}');
    });

    test('fromEntity creates model from entity', () {
      const entity = ${f.singularPascal}Entity(id: 'e-1', name: 'Entity');
      final model = ${f.singularPascal}Model.fromEntity(entity);
      expect(model.id, 'e-1');
      expect(model.name, 'Entity');
    });
  });
}
''');

  // Repository test
  _writeFile('test/features/${f.snake}/data/repositories/${f.singularSnake}_repository_test.dart', '''
import 'package:flutter_bloc_advance/features/${f.snake}/data/repositories/${f.singularSnake}_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('${f.singularPascal}Repository', () {
    test('can be instantiated', () {
      expect(${f.singularPascal}Repository(), isNotNull);
    });
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
/// ${f.pascal} feature — public API.
library;

export 'application/${f.singularSnake}_bloc.dart';
export 'application/${f.singularSnake}_event.dart';
export 'application/${f.singularSnake}_state.dart';
export 'domain/entities/${f.singularSnake}_entity.dart';
export 'domain/repositories/${f.singularSnake}_repository.dart';
export 'navigation/${f.snake}_routes.dart';
''');
}
