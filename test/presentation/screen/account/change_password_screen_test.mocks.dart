// Mocks generated by Mockito 5.4.5 from annotations
// in flutter_bloc_advance/test/presentation/screen/account/change_password_screen_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:flutter_bloc/flutter_bloc.dart' as _i5;
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority_bloc.dart'
    as _i2;
import 'package:flutter_bloc_advance/presentation/screen/change_password/bloc/change_password_bloc.dart'
    as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeAuthorityState_0 extends _i1.SmartFake
    implements _i2.AuthorityState {
  _FakeAuthorityState_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeChangePasswordState_1 extends _i1.SmartFake
    implements _i3.ChangePasswordState {
  _FakeChangePasswordState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [AuthorityBloc].
///
/// See the documentation for Mockito's code generation for more information.
class MockAuthorityBloc extends _i1.Mock implements _i2.AuthorityBloc {
  MockAuthorityBloc() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.AuthorityState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeAuthorityState_0(
          this,
          Invocation.getter(#state),
        ),
      ) as _i2.AuthorityState);

  @override
  _i4.Stream<_i2.AuthorityState> get stream => (super.noSuchMethod(
        Invocation.getter(#stream),
        returnValue: _i4.Stream<_i2.AuthorityState>.empty(),
      ) as _i4.Stream<_i2.AuthorityState>);

  @override
  bool get isClosed => (super.noSuchMethod(
        Invocation.getter(#isClosed),
        returnValue: false,
      ) as bool);

  @override
  void add(_i2.AuthorityEvent? event) => super.noSuchMethod(
        Invocation.method(
          #add,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onEvent(_i2.AuthorityEvent? event) => super.noSuchMethod(
        Invocation.method(
          #onEvent,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void emit(_i2.AuthorityState? state) => super.noSuchMethod(
        Invocation.method(
          #emit,
          [state],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void on<E extends _i2.AuthorityEvent>(
    _i5.EventHandler<E, _i2.AuthorityState>? handler, {
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
          _i5.Transition<_i2.AuthorityEvent, _i2.AuthorityState>? transition) =>
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
  void onChange(_i5.Change<_i2.AuthorityState>? change) => super.noSuchMethod(
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

/// A class which mocks [ChangePasswordBloc].
///
/// See the documentation for Mockito's code generation for more information.
class MockChangePasswordBloc extends _i1.Mock
    implements _i3.ChangePasswordBloc {
  MockChangePasswordBloc() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.ChangePasswordState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeChangePasswordState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.ChangePasswordState);

  @override
  _i4.Stream<_i3.ChangePasswordState> get stream => (super.noSuchMethod(
        Invocation.getter(#stream),
        returnValue: _i4.Stream<_i3.ChangePasswordState>.empty(),
      ) as _i4.Stream<_i3.ChangePasswordState>);

  @override
  bool get isClosed => (super.noSuchMethod(
        Invocation.getter(#isClosed),
        returnValue: false,
      ) as bool);

  @override
  void onTransition(
          _i5.Transition<_i3.ChangePasswordEvent, _i3.ChangePasswordState>?
              transition) =>
      super.noSuchMethod(
        Invocation.method(
          #onTransition,
          [transition],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void add(_i3.ChangePasswordEvent? event) => super.noSuchMethod(
        Invocation.method(
          #add,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onEvent(_i3.ChangePasswordEvent? event) => super.noSuchMethod(
        Invocation.method(
          #onEvent,
          [event],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void emit(_i3.ChangePasswordState? state) => super.noSuchMethod(
        Invocation.method(
          #emit,
          [state],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void on<E extends _i3.ChangePasswordEvent>(
    _i5.EventHandler<E, _i3.ChangePasswordState>? handler, {
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
  _i4.Future<void> close() => (super.noSuchMethod(
        Invocation.method(
          #close,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  void onChange(_i5.Change<_i3.ChangePasswordState>? change) =>
      super.noSuchMethod(
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
