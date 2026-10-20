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
import 'package:flutter_bloc_advance/features/users/presentation/pages/user_extended_info_page.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

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
  Widget host(Widget child, DynamicFormBloc bloc) => MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: BlocProvider<DynamicFormBloc>.value(value: bloc, child: child),
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
          builder: (ctx, state) => BlocProvider<DynamicFormBloc>.value(
            value: bloc,
            child: const UserExtendedInfoPage(userId: '42'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
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

  testWidgets('on DynamicFormFailure with schema shows save_failed snackbar', (tester) async {
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

    expect(find.textContaining('Save failed'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
    // Form is still on screen — the page is preserved, not popped.
    expect(find.byType(UserExtendedInfoPage), findsOneWidget);
  });

  group('certificate pin mismatch', () {
    /// The page wired as its route wires it, on the production ApiClient chain, with [adapter] in the slot of the
    /// certificate-pinning adapter.
    Widget pinnedHost(_FakeHttpClientAdapter adapter, {Locale locale = const Locale('en')}) {
      final apiClient = ApiClient(appConfig: _pinnedProdConfig, secureStorage: FlutterSecureStorageAdapter());
      apiClient.instance.httpClientAdapter = adapter;
      return MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: RepositoryProvider<IDynamicFormRepository>.value(
          value: DynamicFormRepository(apiClient),
          child: Builder(
            builder: (context) => DynamicFormsFeatureRoutes.withBloc(context, const UserExtendedInfoPage(userId: '42')),
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
}
