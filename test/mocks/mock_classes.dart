import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// BLoC imports
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/change_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/forgot_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/register_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/features/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/features/users/application/authority_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';

// Repository imports (concrete)
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';
import 'package:flutter_bloc_advance/features/users/data/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';

// Repository imports (interfaces)
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
// Entity/model imports for fallback values
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/features/account/data/models/change_password.dart';
import 'package:flutter_bloc_advance/features/auth/domain/entities/auth_entity.dart';

// Concrete repository mocks (for BLoC tests that depend on concrete types)
class MockAccountRepository extends Mock implements AccountRepository {}

class MockLoginRepository extends Mock implements LoginRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthorityRepository extends Mock implements IAuthorityRepository {}

class MockMenuRepository extends Mock implements MenuRepository {}

// Interface repository mocks (for use case tests)
class MockIAccountRepository extends Mock implements IAccountRepository {}

class MockIAuthRepository extends Mock implements IAuthRepository {}

class MockIUserRepository extends Mock implements IUserRepository {}

// BLoC mocks (using MockBloc from bloc_test)
class MockAccountBloc extends MockBloc<AccountEvent, AccountState> implements AccountBloc {}

class MockUserBloc extends MockBloc<UserEvent, UserState> implements UserBloc {}

class MockAuthorityBloc extends MockBloc<AuthorityEvent, AuthorityState> implements AuthorityBloc {}

class MockChangePasswordBloc extends MockBloc<ChangePasswordEvent, ChangePasswordState> implements ChangePasswordBloc {}

class MockForgotPasswordBloc extends MockBloc<ForgotPasswordEvent, ForgotPasswordState> implements ForgotPasswordBloc {}

class MockRegisterBloc extends MockBloc<RegisterEvent, RegisterState> implements RegisterBloc {}

class MockLoginBloc extends MockBloc<LoginEvent, LoginState> implements LoginBloc {}

class MockDynamicFormBloc extends MockBloc<DynamicFormEvent, DynamicFormState> implements DynamicFormBloc {}

// Infrastructure mocks
class MockSharedPreferences extends Mock implements SharedPreferences {}

// Fake classes for fallback values
class FakeUserEntity extends Fake implements UserEntity {}

class FakePasswordChangeDTO extends Fake implements PasswordChangeDTO {}

class FakeAuthCredentialsEntity extends Fake implements AuthCredentialsEntity {}

class FakeSendOtpEntity extends Fake implements SendOtpEntity {}

class FakeVerifyOtpEntity extends Fake implements VerifyOtpEntity {}

class FakeAccountEvent extends Fake implements AccountEvent {}

class FakeUserEvent extends Fake implements UserEvent {}

class FakeForgotPasswordEvent extends Fake implements ForgotPasswordEvent {}

class FakeChangePasswordEvent extends Fake implements ChangePasswordEvent {}

class FakeRegisterEvent extends Fake implements RegisterEvent {}

class FakeLoginEvent extends Fake implements LoginEvent {}

class FakeDynamicFormEvent extends Fake implements DynamicFormEvent {}

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
  registerFallbackValue(FakeDynamicFormEvent());
  registerFallbackValue(FakeUri());
  registerFallbackValue(FakeUserEntity());
  registerFallbackValue(FakePasswordChangeDTO());
  registerFallbackValue(FakeAuthCredentialsEntity());
  registerFallbackValue(FakeSendOtpEntity());
  registerFallbackValue(FakeVerifyOtpEntity());
}
