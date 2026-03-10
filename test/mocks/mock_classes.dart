import 'package:bloc_test/bloc_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// BLoC imports
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/change_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/forgot_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/register_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';

// Repository imports
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';

// Repository mocks
class MockAccountRepository extends Mock implements AccountRepository {}

class MockLoginRepository extends Mock implements LoginRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthorityRepository extends Mock implements AuthorityRepository {}

class MockMenuRepository extends Mock implements MenuRepository {}

// BLoC mocks (using MockBloc from bloc_test)
class MockAccountBloc extends MockBloc<AccountEvent, AccountState> implements AccountBloc {}

class MockUserBloc extends MockBloc<UserEvent, UserState> implements UserBloc {}

class MockAuthorityBloc extends MockBloc<AuthorityEvent, AuthorityState> implements AuthorityBloc {}

class MockChangePasswordBloc extends MockBloc<ChangePasswordEvent, ChangePasswordState> implements ChangePasswordBloc {}

class MockForgotPasswordBloc extends MockBloc<ForgotPasswordEvent, ForgotPasswordState> implements ForgotPasswordBloc {}

class MockRegisterBloc extends MockBloc<RegisterEvent, RegisterState> implements RegisterBloc {}

class MockLoginBloc extends MockBloc<LoginEvent, LoginState> implements LoginBloc {}

// Infrastructure mocks
class MockClient extends Mock implements http.Client {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockGetStorage extends Mock implements GetStorage {}

// Fake classes for fallback values
class FakeAccountEvent extends Fake implements AccountEvent {}

class FakeUserEvent extends Fake implements UserEvent {}

class FakeForgotPasswordEvent extends Fake implements ForgotPasswordEvent {}

class FakeChangePasswordEvent extends Fake implements ChangePasswordEvent {}

class FakeRegisterEvent extends Fake implements RegisterEvent {}

class FakeLoginEvent extends Fake implements LoginEvent {}

class FakeUri extends Fake implements Uri {}

/// Register all fallback values needed for mocktail's any() matcher.
/// Call this in setUpAll() for tests that use any() with non-nullable types.
void registerAllFallbackValues() {
  registerFallbackValue(FakeAccountEvent());
  registerFallbackValue(FakeUserEvent());
  registerFallbackValue(FakeForgotPasswordEvent());
  registerFallbackValue(FakeChangePasswordEvent());
  registerFallbackValue(FakeRegisterEvent());
  registerFallbackValue(FakeLoginEvent());
  registerFallbackValue(FakeUri());
}
