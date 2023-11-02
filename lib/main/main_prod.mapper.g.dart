// This file has been generated by the dart_json_mapper v2.2.9
// https://github.com/k-paxian/dart-json-mapper
// @dart = 2.12
import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, JsonMapperAdapter, SerializationOptions, DeserializationOptions, typeOf;
import 'package:flutter_bloc_advance/configuration/environment.dart' as x4 show Environment;
import 'package:flutter_bloc_advance/data/models/jwt_token.dart' as x2 show JWTToken;
import 'package:flutter_bloc_advance/data/models/task.dart' as x0 show Task;
import 'package:flutter_bloc_advance/data/models/user.dart' as x1 show User;
import 'package:flutter_bloc_advance/data/models/user_jwt.dart' as x3 show UserJWT;
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account_bloc.dart' as x7 show AccountStatus;
import 'package:flutter_bloc_advance/presentation/screen/login/bloc/login_bloc.dart' as x8 show LoginStatus;
import 'package:flutter_bloc_advance/presentation/screen/settings/bloc/settings_bloc.dart' as x9 show SettingsStatus;
import 'package:flutter_bloc_advance/presentation/screen/task/list/bloc/task_list_bloc.dart' as x5 show TaskListStatus;
import 'package:flutter_bloc_advance/presentation/screen/task/save/bloc/task_save_bloc.dart' as x6 show TaskSaveStatus;
// This file has been generated by the reflectable package.
// https://github.com/dart-lang/reflectable.

import 'dart:core';
import 'package:dart_json_mapper/src/model/annotations.dart' as prefix0;
import 'package:flutter_bloc_advance/data/models/jwt_token.dart' as prefix3;
import 'package:flutter_bloc_advance/data/models/task.dart' as prefix1;
import 'package:flutter_bloc_advance/data/models/user.dart' as prefix2;
import 'package:flutter_bloc_advance/data/models/user_jwt.dart' as prefix4;

// ignore_for_file: camel_case_types
// ignore_for_file: implementation_imports
// ignore_for_file: prefer_adjacent_string_concatenation
// ignore_for_file: prefer_collection_literals
// ignore_for_file: unnecessary_const

// ignore:unused_import
import 'package:reflectable/mirrors.dart' as m;
// ignore:unused_import
import 'package:reflectable/src/reflectable_builder_based.dart' as r;
// ignore:unused_import
import 'package:reflectable/reflectable.dart' as r show Reflectable;

final _data = <r.Reflectable, r.ReflectorData>{const prefix0.JsonSerializable(): r.ReflectorData(<m.TypeMirror>[r.NonGenericClassMirrorImpl(r'Task', r'.Task', 134217735, 0, const prefix0.JsonSerializable(), const <int>[0, 1, 2, 14, 18], const <int>[19, 20, 21, 22, 23, 14, 15, 16, 17], const <int>[], -1, {}, {}, {r'': (bool b) => ({id = 0, name = '', price = 0}) => b ? prefix1.Task(id: id, name: name, price: price) : null}, -1, 0, const <int>[], const [prefix0.jsonSerializable], null), r.NonGenericClassMirrorImpl(r'User', r'.User', 134217735, 1, const prefix0.JsonSerializable(), const <int>[3, 4, 5, 6, 7, 8, 9, 10, 24, 33, 34, 35], const <int>[36, 37, 21, 38, 23, 34, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33], const <int>[], -1, {}, {}, {r'': (bool b) => ({id = 0, login = '', firstName = '', lastName = '', email = '', langKey = 'en', activated = false, imageUrl = ''}) => b ? prefix2.User(activated: activated, email: email, firstName: firstName, id: id, imageUrl: imageUrl, langKey: langKey, lastName: lastName, login: login) : null}, -1, 1, const <int>[], const [prefix0.jsonSerializable], null), r.NonGenericClassMirrorImpl(r'JWTToken', r'.JWTToken', 134217735, 2, const prefix0.JsonSerializable(), const <int>[11, 39, 40, 43, 44], const <int>[40, 39, 21, 43, 23, 41, 42], const <int>[], -1, {}, {}, {r'': (bool b) => () => b ? prefix3.JWTToken() : null}, -1, 2, const <int>[], const [prefix0.jsonSerializable], null), r.NonGenericClassMirrorImpl(r'UserJWT', r'.UserJWT', 134217735, 3, const prefix0.JsonSerializable(), const <int>[12, 13, 45, 46, 51, 52], const <int>[46, 45, 21, 51, 23, 47, 48, 49, 50], const <int>[], -1, {}, {}, {r'': (bool b) => (username, password) => b ? prefix4.UserJWT(username, password) : null}, -1, 3, const <int>[], const [prefix0.jsonSerializable], null)], <m.DeclarationMirror>[r.VariableMirrorImpl(r'id', 67240965, 0, const prefix0.JsonSerializable(), -1, 4, 4, const <int>[], const [const prefix0.JsonProperty(name: 'id')]), r.VariableMirrorImpl(r'name', 67240965, 0, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [const prefix0.JsonProperty(name: 'name')]), r.VariableMirrorImpl(r'price', 67240965, 0, const prefix0.JsonSerializable(), -1, 4, 4, const <int>[], const [const prefix0.JsonProperty(name: 'price')]), r.VariableMirrorImpl(r'id', 67240965, 1, const prefix0.JsonSerializable(), -1, 4, 4, const <int>[], const [const prefix0.JsonProperty(name: 'id')]), r.VariableMirrorImpl(r'login', 67240965, 1, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [const prefix0.JsonProperty(name: 'login')]), r.VariableMirrorImpl(r'firstName', 67240965, 1, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [const prefix0.JsonProperty(name: 'firstName')]), r.VariableMirrorImpl(r'lastName', 67240965, 1, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [const prefix0.JsonProperty(name: 'lastName')]), r.VariableMirrorImpl(r'email', 67240965, 1, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [const prefix0.JsonProperty(name: 'email')]), r.VariableMirrorImpl(r'langKey', 67240965, 1, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [const prefix0.JsonProperty(name: 'langKey')]), r.VariableMirrorImpl(r'activated', 67240965, 1, const prefix0.JsonSerializable(), -1, 6, 6, const <int>[], const []), r.VariableMirrorImpl(r'imageUrl', 67240965, 1, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const []), r.VariableMirrorImpl(r'idToken', 67239941, 2, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [const prefix0.JsonProperty(name: 'id_token')]), r.VariableMirrorImpl(r'username', 67239941, 3, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [const prefix0.JsonProperty(name: 'username')]), r.VariableMirrorImpl(r'password', 67239941, 3, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [const prefix0.JsonProperty(name: 'password')]), r.MethodMirrorImpl(r'copyWith', 2097154, 0, 0, 0, 0, const <int>[], const <int>[0, 1, 2], const prefix0.JsonSerializable(), const []), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 0, 15), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 1, 16), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 2, 17), r.MethodMirrorImpl(r'', 0, 0, -1, 0, 0, const <int>[], const <int>[3, 4, 5], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'==', 2097154, -1, -1, 7, 7, const <int>[], const <int>[6], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'toString', 2097154, -1, -1, 8, 8, const <int>[], const <int>[], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'noSuchMethod', 524290, -1, -1, -1, -1, const <int>[], const <int>[7], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'hashCode', 2097155, -1, -1, 9, 9, const <int>[], const <int>[], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'runtimeType', 2097155, -1, -1, 10, 10, const <int>[], const <int>[], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'copyWith', 2097154, 1, 1, 1, 1, const <int>[], const <int>[8, 9, 10, 11, 12, 13, 14, 15], const prefix0.JsonSerializable(), const []), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 3, 25), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 4, 26), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 5, 27), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 6, 28), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 7, 29), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 8, 30), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 9, 31), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 10, 32), r.MethodMirrorImpl(r'props', 35651587, 1, -1, 12, 13, const <int>[11], const <int>[], const prefix0.JsonSerializable(), const [override]), r.MethodMirrorImpl(r'stringify', 2097155, 1, -1, 7, 7, const <int>[], const <int>[], const prefix0.JsonSerializable(), const [override]), r.MethodMirrorImpl(r'', 128, 1, -1, 1, 1, const <int>[], const <int>[16, 17, 18, 19, 20, 21, 22, 23], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'==', 2097154, -1, -1, 7, 7, const <int>[], const <int>[24], const prefix0.JsonSerializable(), const [override]), r.MethodMirrorImpl(r'toString', 2097154, -1, -1, 8, 8, const <int>[], const <int>[], const prefix0.JsonSerializable(), const [override]), r.MethodMirrorImpl(r'hashCode', 2097155, -1, -1, 9, 9, const <int>[], const <int>[], const prefix0.JsonSerializable(), const [override]), r.MethodMirrorImpl(r'toString', 2097154, 2, -1, 8, 8, const <int>[], const <int>[], const prefix0.JsonSerializable(), const [override]), r.MethodMirrorImpl(r'==', 2097154, 2, -1, 7, 7, const <int>[], const <int>[25], const prefix0.JsonSerializable(), const [override]), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 11, 41), r.ImplicitSetterMirrorImpl(const prefix0.JsonSerializable(), 11, 42), r.MethodMirrorImpl(r'hashCode', 2097155, 2, -1, 9, 9, const <int>[], const <int>[], const prefix0.JsonSerializable(), const [override]), r.MethodMirrorImpl(r'', 64, 2, -1, 2, 2, const <int>[], const <int>[], const prefix0.JsonSerializable(), const []), r.MethodMirrorImpl(r'toString', 2097154, 3, -1, 8, 8, const <int>[], const <int>[], const prefix0.JsonSerializable(), const [override]), r.MethodMirrorImpl(r'==', 2097154, 3, -1, 7, 7, const <int>[], const <int>[27], const prefix0.JsonSerializable(), const [override]), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 12, 47), r.ImplicitSetterMirrorImpl(const prefix0.JsonSerializable(), 12, 48), r.ImplicitGetterMirrorImpl(const prefix0.JsonSerializable(), 13, 49), r.ImplicitSetterMirrorImpl(const prefix0.JsonSerializable(), 13, 50), r.MethodMirrorImpl(r'hashCode', 2097155, 3, -1, 9, 9, const <int>[], const <int>[], const prefix0.JsonSerializable(), const [override]), r.MethodMirrorImpl(r'', 0, 3, -1, 3, 3, const <int>[], const <int>[28, 29], const prefix0.JsonSerializable(), const [])], <m.ParameterMirror>[r.ParameterMirrorImpl(r'id', 67252230, 14, const prefix0.JsonSerializable(), -1, 4, 4, const <int>[], const [], null, #id), r.ParameterMirrorImpl(r'name', 67252230, 14, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, #name), r.ParameterMirrorImpl(r'price', 67252230, 14, const prefix0.JsonSerializable(), -1, 4, 4, const <int>[], const [], null, #price), r.ParameterMirrorImpl(r'id', 67255302, 18, const prefix0.JsonSerializable(), -1, 4, 4, const <int>[], const [], 0, #id), r.ParameterMirrorImpl(r'name', 67255302, 18, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], '', #name), r.ParameterMirrorImpl(r'price', 67255302, 18, const prefix0.JsonSerializable(), -1, 4, 4, const <int>[], const [], 0, #price), r.ParameterMirrorImpl(r'other', 134348806, 19, const prefix0.JsonSerializable(), -1, 14, 14, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'invocation', 134348806, 21, const prefix0.JsonSerializable(), -1, 15, 15, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'id', 67252230, 24, const prefix0.JsonSerializable(), -1, 4, 4, const <int>[], const [], null, #id), r.ParameterMirrorImpl(r'login', 67252230, 24, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, #login), r.ParameterMirrorImpl(r'firstName', 67252230, 24, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, #firstName), r.ParameterMirrorImpl(r'lastName', 67252230, 24, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, #lastName), r.ParameterMirrorImpl(r'email', 67252230, 24, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, #email), r.ParameterMirrorImpl(r'langKey', 67252230, 24, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, #langKey), r.ParameterMirrorImpl(r'activated', 67252230, 24, const prefix0.JsonSerializable(), -1, 6, 6, const <int>[], const [], null, #activated), r.ParameterMirrorImpl(r'imageUrl', 67252230, 24, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, #imageUrl), r.ParameterMirrorImpl(r'id', 67255302, 35, const prefix0.JsonSerializable(), -1, 4, 4, const <int>[], const [], 0, #id), r.ParameterMirrorImpl(r'login', 67255302, 35, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], '', #login), r.ParameterMirrorImpl(r'firstName', 67255302, 35, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], '', #firstName), r.ParameterMirrorImpl(r'lastName', 67255302, 35, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], '', #lastName), r.ParameterMirrorImpl(r'email', 67255302, 35, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], '', #email), r.ParameterMirrorImpl(r'langKey', 67255302, 35, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], 'en', #langKey), r.ParameterMirrorImpl(r'activated', 67255302, 35, const prefix0.JsonSerializable(), -1, 6, 6, const <int>[], const [], false, #activated), r.ParameterMirrorImpl(r'imageUrl', 67255302, 35, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], '', #imageUrl), r.ParameterMirrorImpl(r'other', 134348806, 36, const prefix0.JsonSerializable(), -1, 14, 14, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'other', 134348806, 40, const prefix0.JsonSerializable(), -1, 14, 14, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'_idToken', 67240038, 42, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'other', 134348806, 46, const prefix0.JsonSerializable(), -1, 14, 14, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'username', 67240966, 52, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'password', 67240966, 52, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'_username', 67240038, 48, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, null), r.ParameterMirrorImpl(r'_password', 67240038, 50, const prefix0.JsonSerializable(), -1, 5, 5, const <int>[], const [], null, null)], <Type>[prefix1.Task, prefix2.User, prefix3.JWTToken, prefix4.UserJWT, int, String, bool, bool, String, int, Type, Object, const m.TypeValue<List>().type, List, Object, Invocation], 4, {r'==': (dynamic instance) => (x) => instance == x, r'toString': (dynamic instance) => instance.toString, r'noSuchMethod': (dynamic instance) => instance.noSuchMethod, r'hashCode': (dynamic instance) => instance.hashCode, r'runtimeType': (dynamic instance) => instance.runtimeType, r'copyWith': (dynamic instance) => instance.copyWith, r'id': (dynamic instance) => instance.id, r'name': (dynamic instance) => instance.name, r'price': (dynamic instance) => instance.price, r'stringify': (dynamic instance) => instance.stringify, r'login': (dynamic instance) => instance.login, r'firstName': (dynamic instance) => instance.firstName, r'lastName': (dynamic instance) => instance.lastName, r'email': (dynamic instance) => instance.email, r'langKey': (dynamic instance) => instance.langKey, r'activated': (dynamic instance) => instance.activated, r'imageUrl': (dynamic instance) => instance.imageUrl, r'props': (dynamic instance) => instance.props, r'idToken': (dynamic instance) => instance.idToken, r'username': (dynamic instance) => instance.username, r'password': (dynamic instance) => instance.password}, {r'idToken=': (dynamic instance, value) => instance.idToken = value, r'username=': (dynamic instance, value) => instance.username = value, r'password=': (dynamic instance, value) => instance.password = value}, null, [])};


final _memberSymbolMap = null;

void _initializeReflectable(JsonMapperAdapter adapter) {
  if (!adapter.isGenerated) {
    return;
  }
  r.data = adapter.reflectableData!;
  r.memberSymbolMap = adapter.memberSymbolMap;
}

final mainProdGeneratedAdapter = JsonMapperAdapter(
  title: 'flutter_bloc_advance',
  url: 'package:flutter_bloc_advance/main/main_prod.dart',
  reflectableData: _data,
  memberSymbolMap: _memberSymbolMap,
  valueDecorators: {
    typeOf<List<x0.Task>>(): (value) => value.cast<x0.Task>(),
    typeOf<Set<x0.Task>>(): (value) => value.cast<x0.Task>(),
    typeOf<List<x1.User>>(): (value) => value.cast<x1.User>(),
    typeOf<Set<x1.User>>(): (value) => value.cast<x1.User>(),
    typeOf<List<x2.JWTToken>>(): (value) => value.cast<x2.JWTToken>(),
    typeOf<Set<x2.JWTToken>>(): (value) => value.cast<x2.JWTToken>(),
    typeOf<List<x3.UserJWT>>(): (value) => value.cast<x3.UserJWT>(),
    typeOf<Set<x3.UserJWT>>(): (value) => value.cast<x3.UserJWT>(),
    typeOf<List<x4.Environment>>(): (value) => value.cast<x4.Environment>(),
    typeOf<Set<x4.Environment>>(): (value) => value.cast<x4.Environment>(),
    typeOf<List<x5.TaskListStatus>>(): (value) => value.cast<x5.TaskListStatus>(),
    typeOf<Set<x5.TaskListStatus>>(): (value) => value.cast<x5.TaskListStatus>(),
    typeOf<List<x6.TaskSaveStatus>>(): (value) => value.cast<x6.TaskSaveStatus>(),
    typeOf<Set<x6.TaskSaveStatus>>(): (value) => value.cast<x6.TaskSaveStatus>(),
    typeOf<List<x7.AccountStatus>>(): (value) => value.cast<x7.AccountStatus>(),
    typeOf<Set<x7.AccountStatus>>(): (value) => value.cast<x7.AccountStatus>(),
    typeOf<List<x8.LoginStatus>>(): (value) => value.cast<x8.LoginStatus>(),
    typeOf<Set<x8.LoginStatus>>(): (value) => value.cast<x8.LoginStatus>(),
    typeOf<List<x9.SettingsStatus>>(): (value) => value.cast<x9.SettingsStatus>(),
    typeOf<Set<x9.SettingsStatus>>(): (value) => value.cast<x9.SettingsStatus>()
},
  enumValues: {
    x4.Environment: x4.Environment.values,
    x5.TaskListStatus: x5.TaskListStatus.values,
    x6.TaskSaveStatus: x6.TaskSaveStatus.values,
    x7.AccountStatus: x7.AccountStatus.values,
    x8.LoginStatus: x8.LoginStatus.values,
    x9.SettingsStatus: x9.SettingsStatus.values
});

Future<JsonMapper> initializeJsonMapperAsync({Iterable<JsonMapperAdapter> adapters = const [], SerializationOptions? serializationOptions, DeserializationOptions? deserializationOptions}) => Future(() => initializeJsonMapper(adapters: adapters, serializationOptions: serializationOptions, deserializationOptions: deserializationOptions));

JsonMapper initializeJsonMapper({Iterable<JsonMapperAdapter> adapters = const [], SerializationOptions? serializationOptions, DeserializationOptions? deserializationOptions}) {
  JsonMapper.globalSerializationOptions = serializationOptions ?? JsonMapper.globalSerializationOptions;
  JsonMapper.globalDeserializationOptions = deserializationOptions ?? JsonMapper.globalDeserializationOptions;    
  JsonMapper.enumerateAdapters([...adapters, mainProdGeneratedAdapter], (JsonMapperAdapter adapter) {
    _initializeReflectable(adapter);
    JsonMapper().useAdapter(adapter);
  });
  return JsonMapper();
}