// Mocks generated by Mockito 5.4.4 from annotations
// in flutter_bloc_advance/test/presentation/screen/user/list_user_screen_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:flutter_bloc/flutter_bloc.dart' as _i5;
import 'package:flutter_bloc_advance/data/models/authority.dart' as _i9;
import 'package:flutter_bloc_advance/data/models/user.dart' as _i7;
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart'
    as _i8;
import 'package:flutter_bloc_advance/data/repository/user_repository.dart'
    as _i6;
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority_bloc.dart'
    as _i3;
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user_bloc.dart'
    as _i2;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeUserState_0 extends _i1.SmartFake implements _i2.UserState {
  _FakeUserState_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeAuthorityState_1 extends _i1.SmartFake
    implements _i3.AuthorityState {
  _FakeAuthorityState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [UserBloc].
///
/// See the documentation for Mockito's code generation for more information.
class MockUserBloc extends _i1.Mock implements _i2.UserBloc {
  MockUserBloc() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.UserState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeUserState_0(
          this,
          Invocation.getter(#state),
        ),
      ) as _i2.UserState);

  @override
  _i4.Stream<_i2.UserState> get stream => (super.noSuchMethod(
        Invocation.getter(#stream),
        returnValue: _i4.Stream<_i2.UserState>.empty(),
      ) as _i4.Stream<_i2.UserState>);

  @override
  bool get isClosed => (super.noSuchMethod(
        Invocation.getter(#isClosed),
        returnValue: false,
      ) as bool);

  @override
  void add(_i2.UserEvent? event) => super.noSuchMethod(
        Invocation.method(
          #add,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onEvent(_i2.UserEvent? event) => super.noSuchMethod(
        Invocation.method(
          #onEvent,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void emit(_i2.UserState? state) => super.noSuchMethod(
        Invocation.method(
          #emit,
          [state],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void on<E extends _i2.UserEvent>(
    _i5.EventHandler<E, _i2.UserState>? handler, {
    _i5.EventTransformer<E>? transformer,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #on,
          [handler],
          {#transformer: transformer},
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onTransition(_i5.Transition<_i2.UserEvent, _i2.UserState>? transition) =>
      super.noSuchMethod(
        Invocation.method(
          #onTransition,
          [transition],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i4.Future<void> close() => (super.noSuchMethod(
        Invocation.method(
          #close,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  void onChange(_i5.Change<_i2.UserState>? change) => super.noSuchMethod(
        Invocation.method(
          #onChange,
          [change],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void addError(
    Object? error, [
    StackTrace? stackTrace,
  ]) =>
      super.noSuchMethod(
        Invocation.method(
          #addError,
          [
            error,
            stackTrace,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onError(
    Object? error,
    StackTrace? stackTrace,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #onError,
          [
            error,
            stackTrace,
          ],
        ),
        returnValueForMissingStub: null,
      );
}

/// A class which mocks [UserRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockUserRepository extends _i1.Mock implements _i6.UserRepository {
  MockUserRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i7.User?> retrieve(String? id) => (super.noSuchMethod(
        Invocation.method(
          #retrieve,
          [id],
        ),
        returnValue: _i4.Future<_i7.User?>.value(),
      ) as _i4.Future<_i7.User?>);

  @override
  _i4.Future<_i7.User?> retrieveByLogin(String? login) => (super.noSuchMethod(
        Invocation.method(
          #retrieveByLogin,
          [login],
        ),
        returnValue: _i4.Future<_i7.User?>.value(),
      ) as _i4.Future<_i7.User?>);

  @override
  _i4.Future<_i7.User?> create(_i7.User? user) => (super.noSuchMethod(
        Invocation.method(
          #create,
          [user],
        ),
        returnValue: _i4.Future<_i7.User?>.value(),
      ) as _i4.Future<_i7.User?>);

  @override
  _i4.Future<_i7.User?> update(_i7.User? user) => (super.noSuchMethod(
        Invocation.method(
          #update,
          [user],
        ),
        returnValue: _i4.Future<_i7.User?>.value(),
      ) as _i4.Future<_i7.User?>);

  @override
  _i4.Future<List<_i7.User?>> list({
    int? page = 0,
    int? size = 10,
    List<String>? sort = const [r'id,desc'],
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #list,
          [],
          {
            #page: page,
            #size: size,
            #sort: sort,
          },
        ),
        returnValue: _i4.Future<List<_i7.User?>>.value(<_i7.User?>[]),
      ) as _i4.Future<List<_i7.User?>>);

  @override
  _i4.Future<List<_i7.User>> listByAuthority(
    int? page,
    int? size,
    String? authority,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #listByAuthority,
          [
            page,
            size,
            authority,
          ],
        ),
        returnValue: _i4.Future<List<_i7.User>>.value(<_i7.User>[]),
      ) as _i4.Future<List<_i7.User>>);

  @override
  _i4.Future<List<_i7.User>> listByNameAndRole(
    int? page,
    int? size,
    String? name,
    String? authority,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #listByNameAndRole,
          [
            page,
            size,
            name,
            authority,
          ],
        ),
        returnValue: _i4.Future<List<_i7.User>>.value(<_i7.User>[]),
      ) as _i4.Future<List<_i7.User>>);

  @override
  _i4.Future<void> delete(String? id) => (super.noSuchMethod(
        Invocation.method(
          #delete,
          [id],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);
}

/// A class which mocks [AuthorityBloc].
///
/// See the documentation for Mockito's code generation for more information.
class MockAuthorityBloc extends _i1.Mock implements _i3.AuthorityBloc {
  MockAuthorityBloc() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.AuthorityState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeAuthorityState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.AuthorityState);

  @override
  _i4.Stream<_i3.AuthorityState> get stream => (super.noSuchMethod(
        Invocation.getter(#stream),
        returnValue: _i4.Stream<_i3.AuthorityState>.empty(),
      ) as _i4.Stream<_i3.AuthorityState>);

  @override
  bool get isClosed => (super.noSuchMethod(
        Invocation.getter(#isClosed),
        returnValue: false,
      ) as bool);

  @override
  void add(_i3.AuthorityEvent? event) => super.noSuchMethod(
        Invocation.method(
          #add,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onEvent(_i3.AuthorityEvent? event) => super.noSuchMethod(
        Invocation.method(
          #onEvent,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void emit(_i3.AuthorityState? state) => super.noSuchMethod(
        Invocation.method(
          #emit,
          [state],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void on<E extends _i3.AuthorityEvent>(
    _i5.EventHandler<E, _i3.AuthorityState>? handler, {
    _i5.EventTransformer<E>? transformer,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #on,
          [handler],
          {#transformer: transformer},
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onTransition(
          _i5.Transition<_i3.AuthorityEvent, _i3.AuthorityState>? transition) =>
      super.noSuchMethod(
        Invocation.method(
          #onTransition,
          [transition],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i4.Future<void> close() => (super.noSuchMethod(
        Invocation.method(
          #close,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  void onChange(_i5.Change<_i3.AuthorityState>? change) => super.noSuchMethod(
        Invocation.method(
          #onChange,
          [change],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void addError(
    Object? error, [
    StackTrace? stackTrace,
  ]) =>
      super.noSuchMethod(
        Invocation.method(
          #addError,
          [
            error,
            stackTrace,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onError(
    Object? error,
    StackTrace? stackTrace,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #onError,
          [
            error,
            stackTrace,
          ],
        ),
        returnValueForMissingStub: null,
      );
}

/// A class which mocks [AuthorityRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockAuthorityRepository extends _i1.Mock
    implements _i8.AuthorityRepository {
  MockAuthorityRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i9.Authority?> create(_i9.Authority? authority) =>
      (super.noSuchMethod(
        Invocation.method(
          #create,
          [authority],
        ),
        returnValue: _i4.Future<_i9.Authority?>.value(),
      ) as _i4.Future<_i9.Authority?>);

  @override
  _i4.Future<List<String?>> list() => (super.noSuchMethod(
        Invocation.method(
          #list,
          [],
        ),
        returnValue: _i4.Future<List<String?>>.value(<String?>[]),
      ) as _i4.Future<List<String?>>);

  @override
  _i4.Future<_i9.Authority?> retrieve(String? id) => (super.noSuchMethod(
        Invocation.method(
          #retrieve,
          [id],
        ),
        returnValue: _i4.Future<_i9.Authority?>.value(),
      ) as _i4.Future<_i9.Authority?>);

  @override
  _i4.Future<void> delete(String? id) => (super.noSuchMethod(
        Invocation.method(
          #delete,
          [id],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);
}
