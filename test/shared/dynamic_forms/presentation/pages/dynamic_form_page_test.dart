@Tags(['widget'])
library;

import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/infrastructure/http/api_client.dart';
import 'package:flutter_bloc_advance/infrastructure/http/certificate_pinner.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/entities/form_schema_entity.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/domain/repositories/dynamic_form_repository.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/navigation/dynamic_forms_routes.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/presentation/pages/dynamic_form_page.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/presentation/widgets/dynamic_form_renderer.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';
import '../../../../support/unsaved_changes_host.dart';

/// Production chain (no MockInterceptor) with certificate pinning configured.
const _pinnedProdConfig = AppConfig(
  environment: Environment.prod,
  apiBaseUrl: 'https://api.example.test',
  certificatePins: ['test-pin'],
  idleTimeout: null,
);

/// Fails every request as the pinning adapter fails a server whose certificate matches no configured pin.
class _PinMismatchAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw const CertificatePinningException('api.example.test', 443);
  }

  @override
  void close({bool force = false}) {}
}

Widget _buildTestWidget(MockDynamicFormBloc bloc, {Locale locale = const Locale('en')}) {
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
        Scaffold(
          body: BlocProvider<DynamicFormBloc>.value(
            value: bloc,
            child: const DynamicFormPage(formId: 'test_form'),
          ),
        ),
      ),
    ),
  );
}

const _testSchema = FormSchemaEntity(
  id: 'test_form',
  title: 'Test Form',
  description: 'A test form',
  fields: [
    FormFieldEntity(type: FormFieldType.text, key: 'name', label: 'Full Name'),
    FormFieldEntity(type: FormFieldType.email, key: 'email', label: 'Email'),
    FormFieldEntity(type: FormFieldType.dropdown, key: 'source', label: 'Source', options: ['Web', 'Referral']),
  ],
  submitAction: FormSubmitAction(method: 'POST', endpoint: '/leads'),
);

void main() {
  late MockDynamicFormBloc mockBloc;

  setUp(() {
    mockBloc = MockDynamicFormBloc();
  });

  tearDown(() {
    mockBloc.close();
  });

  group('DynamicFormPage', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator when status is loading', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormLoading());

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(DynamicFormRenderer), findsNothing);
        expect(find.byType(AppErrorState), findsNothing);
      });
    });

    group('failure state', () {
      testWidgets('shows AppErrorState when status is failure', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormFailure(error: 'Network error'));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.byType(AppErrorState), findsOneWidget);
        expect(find.text('Error'), findsOneWidget);
        // The raw error is for the log; the user reads the generic message in the app language.
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Network error'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('shows the generic message instead of an error the app has no code for', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormFailure(error: 'Failed to load form'));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.byType(AppErrorState), findsOneWidget);
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Failed to load form'), findsNothing);
      });

      testWidgets('shows the error state and its retry button in Turkish', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormFailure(error: 'Network error'));

        await tester.pumpWidget(_buildTestWidget(mockBloc, locale: const Locale('tr')));
        await tester.pump();

        expect(find.text('Hata'), findsOneWidget);
        expect(find.text('Bir şeyler ters gitti'), findsOneWidget);
        expect(find.text('Tekrar Dene'), findsOneWidget);
      });

      testWidgets('shows retry button in error state', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormFailure(error: 'Something went wrong'));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.text('Retry'), findsOneWidget);
      });

      // Regression: the error state showed the exception text, host and port included.
      testWidgets('shows the insecure-connection message, not the host and port, when a pin mismatch fails the load', (
        tester,
      ) async {
        // The page wired as its route wires it, on the production ApiClient chain.
        final apiClient = ApiClient(appConfig: _pinnedProdConfig, secureStorage: FlutterSecureStorageAdapter());
        apiClient.instance.httpClientAdapter = _PinMismatchAdapter();

        await tester.pumpWidget(
          withUnsavedChangesRegistry(
            MaterialApp.router(
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              routerConfig: singlePageRouter(
                Scaffold(
                  body: RepositoryProvider<IDynamicFormRepository>.value(
                    value: DynamicFormRepository(apiClient),
                    child: Builder(
                      builder: (context) =>
                          DynamicFormsFeatureRoutes.withBloc(context, const DynamicFormPage(formId: 'test_form')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppErrorState), findsOneWidget);
        expect(
          find.text(
            'The connection could not be verified as secure, so it was blocked. Try again later or on another network.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('api.example.test'), findsNothing);
        expect(find.textContaining('443'), findsNothing);
      });
    });

    group('initial state', () {
      testWidgets('shows CircularProgressIndicator while bloc is in DynamicFormInitial', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormInitial());

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(DynamicFormRenderer), findsNothing);
      });
    });

    group('loaded state', () {
      testWidgets('shows form title and DynamicFormRenderer when loaded', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormLoaded(schema: _testSchema));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.text('Test Form'), findsOneWidget);
        expect(find.byType(DynamicFormRenderer), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(AppErrorState), findsNothing);
      });

      testWidgets('renders form fields when loaded', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormLoaded(schema: _testSchema));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Source'), findsOneWidget);
      });

      testWidgets('shows submit button when form is loaded and not submitting', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormLoaded(schema: _testSchema));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        expect(find.text('Submit'), findsOneWidget);
      });
    });

    group('submitting state', () {
      testWidgets('renders form as readOnly when submitting', (tester) async {
        when(() => mockBloc.state).thenReturn(const DynamicFormSubmitting(schema: _testSchema));

        await tester.pumpWidget(_buildTestWidget(mockBloc));

        // Form should still be visible (not loading indicator)
        expect(find.byType(DynamicFormRenderer), findsOneWidget);
        expect(find.text('Test Form'), findsOneWidget);
      });
    });

    group('submitted state', () {
      testWidgets('shows snackbar when status transitions to submitted', (tester) async {
        final statesController = MockDynamicFormBloc();
        whenListen(
          statesController,
          Stream<DynamicFormState>.fromIterable([
            const DynamicFormLoaded(schema: _testSchema),
            const DynamicFormSubmitted(schema: _testSchema),
          ]),
          initialState: const DynamicFormLoaded(schema: _testSchema),
        );

        await tester.pumpWidget(_buildTestWidget(statesController));
        await tester.pump();

        expect(find.text('Form submitted successfully'), findsOneWidget);

        statesController.close();
      });

      testWidgets('says the form was submitted in Turkish', (tester) async {
        final statesController = MockDynamicFormBloc();
        whenListen(
          statesController,
          Stream<DynamicFormState>.fromIterable([const DynamicFormSubmitted(schema: _testSchema)]),
          initialState: const DynamicFormLoaded(schema: _testSchema),
        );

        await tester.pumpWidget(_buildTestWidget(statesController, locale: const Locale('tr')));
        await tester.pump();

        expect(find.text('Form başarıyla gönderildi'), findsOneWidget);

        statesController.close();
      });
    });
  });
}
