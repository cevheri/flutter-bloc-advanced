// Mocks generated by Mockito 5.4.5 from annotations
// in flutter_bloc_advance/test/conf/local_storage_getx_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;
import 'dart:ui' as _i7;

import 'package:flutter/widgets.dart' as _i8;
import 'package:get/utils.dart' as _i3;
import 'package:get_storage/src/storage_impl.dart' as _i2;
import 'package:get_storage/src/value.dart' as _i4;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i6;

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

class _FakeMicrotask_0 extends _i1.SmartFake implements _i2.Microtask {
  _FakeMicrotask_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeGetQueue_1 extends _i1.SmartFake implements _i3.GetQueue {
  _FakeGetQueue_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeValueStorage_2<T> extends _i1.SmartFake
    implements _i4.ValueStorage<T> {
  _FakeValueStorage_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [GetStorage].
///
/// See the documentation for Mockito's code generation for more information.
class MockGetStorage extends _i1.Mock implements _i2.GetStorage {
  MockGetStorage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.Microtask get microtask => (super.noSuchMethod(
        Invocation.getter(#microtask),
        returnValue: _FakeMicrotask_0(
          this,
          Invocation.getter(#microtask),
        ),
      ) as _i2.Microtask);

  @override
  _i3.GetQueue get queue => (super.noSuchMethod(
        Invocation.getter(#queue),
        returnValue: _FakeGetQueue_1(
          this,
          Invocation.getter(#queue),
        ),
      ) as _i3.GetQueue);

  @override
  set queue(_i3.GetQueue? _queue) => super.noSuchMethod(
        Invocation.setter(
          #queue,
          _queue,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i5.Future<bool> get initStorage => (super.noSuchMethod(
        Invocation.getter(#initStorage),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  set initStorage(_i5.Future<bool>? _initStorage) => super.noSuchMethod(
        Invocation.setter(
          #initStorage,
          _initStorage,
        ),
        returnValueForMissingStub: null,
      );

  @override
  Map<String, dynamic> get changes => (super.noSuchMethod(
        Invocation.getter(#changes),
        returnValue: <String, dynamic>{},
      ) as Map<String, dynamic>);

  @override
  _i4.ValueStorage<Map<String, dynamic>> get listenable => (super.noSuchMethod(
        Invocation.getter(#listenable),
        returnValue: _FakeValueStorage_2<Map<String, dynamic>>(
          this,
          Invocation.getter(#listenable),
        ),
      ) as _i4.ValueStorage<Map<String, dynamic>>);

  @override
  T? read<T>(String? key) => (super.noSuchMethod(Invocation.method(
        #read,
        [key],
      )) as T?);

  @override
  T getKeys<T>() => (super.noSuchMethod(
        Invocation.method(
          #getKeys,
          [],
        ),
        returnValue: _i6.dummyValue<T>(
          this,
          Invocation.method(
            #getKeys,
            [],
          ),
        ),
      ) as T);

  @override
  T getValues<T>() => (super.noSuchMethod(
        Invocation.method(
          #getValues,
          [],
        ),
        returnValue: _i6.dummyValue<T>(
          this,
          Invocation.method(
            #getValues,
            [],
          ),
        ),
      ) as T);

  @override
  bool hasData(String? key) => (super.noSuchMethod(
        Invocation.method(
          #hasData,
          [key],
        ),
        returnValue: false,
      ) as bool);

  @override
  _i7.VoidCallback listen(_i7.VoidCallback? value) => (super.noSuchMethod(
        Invocation.method(
          #listen,
          [value],
        ),
        returnValue: () {},
      ) as _i7.VoidCallback);

  @override
  _i7.VoidCallback listenKey(
    String? key,
    _i8.ValueSetter<dynamic>? callback,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #listenKey,
          [
            key,
            callback,
          ],
        ),
        returnValue: () {},
      ) as _i7.VoidCallback);

  @override
  _i5.Future<void> write(
    String? key,
    dynamic value,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #write,
          [
            key,
            value,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  void writeInMemory(
    String? key,
    dynamic value,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #writeInMemory,
          [
            key,
            value,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i5.Future<void> writeIfNull(
    String? key,
    dynamic value,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #writeIfNull,
          [
            key,
            value,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> remove(String? key) => (super.noSuchMethod(
        Invocation.method(
          #remove,
          [key],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> erase() => (super.noSuchMethod(
        Invocation.method(
          #erase,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> save() => (super.noSuchMethod(
        Invocation.method(
          #save,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
}
