@Tags(['widget'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/navigation/dynamic_forms_routes.dart';
import 'package:flutter_bloc_advance/shared/widgets/unsaved_changes_guard.dart';
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_extended_info_page.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/unsaved_changes_host.dart';
import '../../../../support/test_env.dart';

class _MockBloc extends MockBloc<DynamicFormEvent, DynamicFormState> implements DynamicFormBloc {}

/// Production chain (no MockInterceptor) with certificate pinning configured.
const _pinnedProdConfig = AppConfig(
  environment: Environment.prod,
  apiBaseUrl: 'https://api.example.test',
  certificatePins: ['test-pin'],
  idleTimeout: null,
);

/// Sits in the slot of the certificate-pinning adapter and answers from a queue. A queued
/// [CertificatePinningException] fails the request the way the pinning adapter does when the server's certificate
/// matches no configured pin.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  final _replies = <Object>[];

  void reply(String body) => _replies.add(body);

  void failPinMismatch() => _replies.add(const CertificatePinningException('api.example.test', 443));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    return switch (_replies.removeAt(0)) {
      final String body => ResponseBody.fromString(
        body,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
      final Object error => throw error,
    };
  }

  @override
  void close({bool force = false}) {}
}

/// A bundle whose form saves with PUT /admin/users/extended/{userId}.
final _bundleJson = jsonEncode({
  'schema': {
    'id': 'user_extended_info',
    'title': 'Extended Information',
    'submitAction': {'method': 'PUT', 'endpoint': '/admin/users/extended'},
    'fields': [
      {'type': 'text', 'key': 'firstName', 'label': 'First name'},
    ],
  },
  'values': {'firstName': 'Alice'},
});

const _insecureConnectionMessage =
    'The connection could not be verified as secure, so it was blocked. Try again later or on another network.';

void main() {
  Widget host(Widget child, DynamicFormBloc bloc) => withUnsavedChangesRegistry(
    MaterialApp.router(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      routerConfig: singlePageRouter(BlocProvider<DynamicFormBloc>.value(value: bloc, child: child)),
    ),
  );

  testWidgets('renders loading indicator while bloc is Loading', (tester) async {
    final bloc = _MockBloc();
    whenListen(bloc, const Stream<DynamicFormState>.empty(), initialState: const DynamicFormLoading());
    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '1'), bloc));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders form fields when bloc is Loaded', (tester) async {
    final bloc = _MockBloc();
    whenListen(
      bloc,
      const Stream<DynamicFormState>.empty(),
      initialState: const DynamicFormLoaded(
        schema: FormSchemaEntity(
          id: 'user_extended_info',
          title: 'Extended Information',
          fields: [FormFieldEntity(type: FormFieldType.text, key: 'firstName', label: 'First name')],
        ),
        initialValues: {'firstName': 'Alice'},
      ),
    );
    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '1'), bloc));
    await tester.pumpAndSettle();
    expect(find.text('First name'), findsOneWidget);
  });

  testWidgets('dispatches DynamicFormLoadBundleEvent on init with correct endpoint', (tester) async {
    final bloc = _MockBloc();
    whenListen(bloc, const Stream<DynamicFormState>.empty(), initialState: const DynamicFormInitial());
    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '42'), bloc));
    await tester.pump();
    verify(
      () => bloc.add(
        any(
          that: isA<DynamicFormLoadBundleEvent>()
              .having((e) => e.basePath, 'basePath', '/admin/users/extended')
              .having((e) => e.pathParams, 'pathParams', '42'),
        ),
      ),
    ).called(1);
  });

  testWidgets('on DynamicFormSubmitted shows saved snackbar and pops the route', (tester) async {
    final bloc = _MockBloc();
    const schema = FormSchemaEntity(
      id: 'user_extended_info',
      title: 'Extended Information',
      fields: [FormFieldEntity(type: FormFieldType.text, key: 'firstName', label: 'First name')],
    );
    const initial = DynamicFormLoaded(schema: schema);
    final submitted = DynamicFormSubmitted(schema: schema, submitResponse: '{"ok":true}');

    whenListen(bloc, Stream.fromIterable([submitted]), initialState: initial);

    // Use GoRouter so context.canPop() / context.pop() work correctly.
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (ctx, state) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/extended',
          onExit: confirmLeavingUnsavedChanges,
          builder: (ctx, state) => BlocProvider<DynamicFormBloc>.value(
            value: bloc,
            child: const UserExtendedInfoPage(userId: '42'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      withUnsavedChangesRegistry(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
        ),
      ),
    );

    // Push (not go) so /home stays in the stack and context.canPop() returns true.
    router.push('/extended');
    await tester.pumpAndSettle();

    // The whenListen stream has already emitted Submitted — verify snackbar.
    expect(find.text('Saved'), findsOneWidget);

    // After the snackbar and pop animation settle, the page is gone.
    await tester.pumpAndSettle();
    expect(find.byType(UserExtendedInfoPage), findsNothing);
  });

  testWidgets('on DynamicFormFailure with schema shows save_failed snackbar with the generic message', (tester) async {
    final bloc = _MockBloc();
    const schema = FormSchemaEntity(
      id: 'user_extended_info',
      title: 'Extended Information',
      fields: [FormFieldEntity(type: FormFieldType.text, key: 'firstName', label: 'First name')],
    );
    const initial = DynamicFormLoaded(schema: schema);
    const failure = DynamicFormFailure(error: 'boom', schema: schema);

    whenListen(bloc, Stream.fromIterable([failure]), initialState: initial);

    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '42'), bloc));
    await tester.pumpAndSettle();

    // The repository's raw text is for the log; the user reads the generic message in the app language.
    expect(find.text('Save failed: Something went wrong'), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    // Form is still on screen — the page is preserved, not popped.
    expect(find.byType(UserExtendedInfoPage), findsOneWidget);
  });

  testWidgets('on DynamicFormFailure without a schema shows the generic message, not the raw error', (tester) async {
    final bloc = _MockBloc();
    whenListen(
      bloc,
      const Stream<DynamicFormState>.empty(),
      initialState: const DynamicFormFailure(error: 'Form id is required'),
    );

    await tester.pumpWidget(host(const UserExtendedInfoPage(userId: '42'), bloc));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Form id is required'), findsNothing);
  });

  group('certificate pin mismatch', () {
    /// The page wired as its route wires it, on the production ApiClient chain, with [adapter] in the slot of the
    /// certificate-pinning adapter.
    Widget pinnedHost(_FakeHttpClientAdapter adapter, {Locale locale = const Locale('en')}) {
      final apiClient = ApiClient(appConfig: _pinnedProdConfig, secureStorage: FlutterSecureStorageAdapter());
      apiClient.instance.httpClientAdapter = adapter;
      return withUnsavedChangesRegistry(
        MaterialApp.router(
          locale: locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          routerConfig: singlePageRouter(
            RepositoryProvider<IDynamicFormRepository>.value(
              value: DynamicFormRepository(apiClient),
              child: Builder(
                builder: (context) =>
                    DynamicFormsFeatureRoutes.withBloc(context, const UserExtendedInfoPage(userId: '42')),
              ),
            ),
          ),
        ),
      );
    }

    // Regression: the page showed the exception text, host and port included, where the form belongs.
    for (final (locale, message) in [
      ('en', _insecureConnectionMessage),
      (
        'tr',
        'Bağlantının güvenli olduğu doğrulanamadığı için engellendi. Daha sonra ya da başka bir ağda tekrar deneyin.',
      ),
    ]) {
      testWidgets('shows the $locale insecure-connection message, not the host and port, when the load fails', (
        tester,
      ) async {
        final adapter = _FakeHttpClientAdapter()..failPinMismatch();

        await tester.pumpWidget(pinnedHost(adapter, locale: Locale(locale)));
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
        expect(find.textContaining('api.example.test'), findsNothing);
        expect(find.textContaining('443'), findsNothing);
      });
    }

    // Regression: the save-failed snack bar showed the exception text, host and port included.
    testWidgets('shows the insecure-connection message, not the host and port, when the save fails', (tester) async {
      final adapter = _FakeHttpClientAdapter()
        ..reply(_bundleJson)
        ..failPinMismatch();

      await tester.pumpWidget(pinnedHost(adapter));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Save failed: $_insecureConnectionMessage'), findsOneWidget);
      expect(find.textContaining('api.example.test'), findsNothing);
      expect(find.textContaining('443'), findsNothing);
    });
  });
  // Regression: the new password field had no length rule, so a 1 or 200 character password was sent to the server.
  group('new password length', () {
    const label = 'New password (optional)';

    /// The page on the mock-backed client, so the form is the one the GET_admin_users_extended mock serves.
    Widget mockHost() => withUnsavedChangesRegistry(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => RepositoryProvider<IDynamicFormRepository>.value(
                value: DynamicFormRepository(TestEnv.apiClient()),
                child: Builder(
                  builder: (context) =>
                      DynamicFormsFeatureRoutes.withBloc(context, const UserExtendedInfoPage(userId: 'user-1')),
                ),
              ),
            ),
          ],
        ),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
      ),
    );

    /// Types each of [typed] into the field in turn, then submits.
    Future<void> submitWithPassword(WidgetTester tester, List<String> typed) async {
      TestEnv.authenticate();
      await tester.pumpWidget(mockHost());
      await tester.pumpAndSettle();
      final field = find.widgetWithText(TextField, label);
      for (final text in typed) {
        await tester.ensureVisible(field);
        await tester.enterText(field, text);
      }
      await tester.ensureVisible(find.text('Submit'));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
    }

    for (final (length, error) in [
      (3, '$label must be at least 4 characters'),
      (21, '$label must be at most 20 characters'),
    ]) {
      testWidgets('rejects a $length character password', (tester) async {
        await submitWithPassword(tester, ['a' * length]);

        expect(find.text(error), findsOneWidget);
        expect(find.text('Saved'), findsNothing);
      });
    }

    for (final length in [4, 20]) {
      testWidgets('saves a $length character password', (tester) async {
        await submitWithPassword(tester, ['a' * length]);

        expect(find.textContaining('must be at'), findsNothing);
        expect(find.text('Saved'), findsOneWidget);
      });
    }

    testWidgets('saves without a password, since the field is optional', (tester) async {
      await submitWithPassword(tester, const []);

      expect(find.textContaining('must be at'), findsNothing);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('saves when a typed password is cleared again, since the field is optional', (tester) async {
      await submitWithPassword(tester, const ['abc', '']);

      expect(find.textContaining('must be at'), findsNothing);
      expect(find.text('Saved'), findsOneWidget);
    });
  });
}
