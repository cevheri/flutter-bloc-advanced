import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/account/account_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils.dart';
import 'account_screen_test.mocks.dart';

@GenerateMocks([AccountBloc, AccountRepository, UserBloc, UserRepository])
void main() {
  late MockAccountRepository mockAccountRepository;
  late MockAccountBloc mockAccountBloc;
  late MockUserBloc mockUserBloc;
  late TestUtils testUtils;

  setUp(() async {
    testUtils = TestUtils();
    await testUtils.setupUnitTest();

    mockAccountRepository = MockAccountRepository();
    mockAccountBloc = MockAccountBloc();
    mockUserBloc = MockUserBloc();
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

  Widget buildTestableWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountBloc>.value(value: mockAccountBloc),
        BlocProvider<UserBloc>.value(value: mockUserBloc),
      ],
      child: MaterialApp(
        home: AccountScreen(),
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

  group('AccountScreen Tests', () {
    testWidgets('Should render account screen with user data', (tester) async {
      // ARRANGE
      const mockUser = User(
        id: 'test-1',
        login: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        activated: true,
      );

      final accountStateController = StreamController<AccountState>.broadcast();
      when(mockAccountBloc.stream).thenAnswer((_) => accountStateController.stream);
      when(mockAccountBloc.state).thenReturn(const AccountState(data: mockUser, status: AccountStatus.success));

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      // Clean up
      await accountStateController.close();
    });

    testWidgets('Should handle form submission with changes', (tester) async {
      // ARRANGE
      const initialUser = User(
        id: 'test-1',
        login: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        activated: true,
      );

      final accountStateController = StreamController<AccountState>.broadcast();
      final userStateController = StreamController<UserState>.broadcast();

      when(mockAccountBloc.stream).thenAnswer((_) => accountStateController.stream);
      when(mockAccountBloc.state).thenReturn(const AccountState(data: initialUser, status: AccountStatus.success));

      when(mockUserBloc.stream).thenAnswer((_) => userStateController.stream);
      when(mockUserBloc.state).thenReturn(const UserState());

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Form alanlarını değiştir
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Yeni İsim');
      await tester.enterText(find.byKey(const Key('userEditorLastNameFieldKey')), 'Yeni Soyisim');

      // Kaydet butonuna tıkla
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      // ASSERT
      verify(mockUserBloc.add(any)).called(greaterThan(0));

      // Clean up
      await accountStateController.close();
      await userStateController.close();
    });

    testWidgets('Should show warning dialog on back button with unsaved changes', (tester) async {
      // ARRANGE
      const mockUser = User(
        id: 'test-1',
        login: 'testuser',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        activated: true,
      );

      final accountStateController = StreamController<AccountState>.broadcast();
      when(mockAccountBloc.stream).thenAnswer((_) => accountStateController.stream);
      when(mockAccountBloc.state).thenReturn(const AccountState(data: mockUser, status: AccountStatus.success));

      // ACT
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Form alanını değiştir
      await tester.enterText(find.byKey(const Key('userEditorFirstNameFieldKey')), 'Değiştirilmiş İsim');

      // Geri butonuna tıkla
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text(S.current.warning), findsOneWidget);
      expect(find.text(S.current.unsaved_changes), findsOneWidget);

      // Clean up
      await accountStateController.close();
    });
  });
}
