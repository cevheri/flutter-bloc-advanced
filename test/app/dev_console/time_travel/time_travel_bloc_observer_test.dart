import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_bloc_observer.dart';
import 'package:flutter_bloc_advance/app/dev_console/time_travel/time_travel_store.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/change_password_usecase.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/data/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/features/auth/application/change_password_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/login_bloc.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/authenticate_user_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/clear_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/persist_auth_session_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/send_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/verify_otp_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:flutter_bloc_advance/infrastructure/http/dev_console_store.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/secure_storage.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_bloc.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_event.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/dynamic_form_state.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/usecases/load_form_bundle_usecase.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/usecases/load_form_schema_usecase.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/application/usecases/submit_form_usecase.dart';
import 'package:flutter_bloc_advance/shared/dynamic_forms/data/repositories/dynamic_form_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_env.dart';

void main() {
  late BlocObserver previousObserver;

  setUp(() {
    previousObserver = Bloc.observer;
    Bloc.observer = TimeTravelBlocObserver();
    DevConsoleStore.instance.clearAll();
    TimeTravelStore.instance.clear();
  });

  tearDown(() {
    Bloc.observer = previousObserver;
    DevConsoleStore.instance.clearAll();
    TimeTravelStore.instance.clear();
  });

  // Regression: AppBootstrap installs this observer in every debug build, and it records the text of each event and
  // state. The events of the sign-in, OTP and change password forms, and of a dynamic form submit, printed the
  // password, the code, both passwords and the admin-set password, so the BLoC and Time Travel tabs of the dev console
  // showed them, and their Copy and Export buttons put them on the clipboard.
  test('records the sign-in, OTP, change password and form submit flows without their secrets', () async {
    const secrets = ['S3cret!pw', '493817', 'OldPass#1', 'NewPass#2', 'Adm1nSet!Pw'];
    final api = TestEnv.apiClient();
    final secureStorage = FlutterSecureStorageAdapter();
    final loginRepository = LoginRepository(apiClient: api, secureStorage: secureStorage);
    final formRepository = DynamicFormRepository(api);
    final sessionRepository = AuthSessionRepository(secureStorage: secureStorage);
    final login = LoginBloc(
      authenticateUserUseCase: AuthenticateUserUseCase(loginRepository),
      sendOtpUseCase: SendOtpUseCase(loginRepository),
      verifyOtpUseCase: VerifyOtpUseCase(loginRepository),
      getAccountUseCase: GetAccountUseCase(AccountRepository(api)),
      persistAuthSessionUseCase: PersistAuthSessionUseCase(sessionRepository),
      clearAuthSessionUseCase: ClearAuthSessionUseCase(sessionRepository),
    );
    final changePassword = ChangePasswordBloc(changePasswordUseCase: ChangePasswordUseCase(AccountRepository(api)));
    final form = DynamicFormBloc(
      loadFormSchemaUseCase: LoadFormSchemaUseCase(formRepository),
      submitFormUseCase: SubmitFormUseCase(formRepository),
      loadFormBundleUseCase: LoadFormBundleUseCase(formRepository),
    );

    login.add(const LoginFormSubmitted(username: 'admin', password: 'S3cret!pw'));
    await login.stream.firstWhere((s) => s is LoginLoadedState || s is LoginErrorState);
    login.add(const VerifyOtpSubmitted(email: 'otp.user@example.com', otpCode: '493817'));
    await login.stream.firstWhere((s) => s is LoginLoadedState || s is LoginErrorState);
    changePassword.add(const ChangePasswordChanged(currentPassword: 'OldPass#1', newPassword: 'NewPass#2'));
    await changePassword.stream.firstWhere((s) => s is ChangePasswordSuccessState || s is ChangePasswordFailureState);
    form.add(const DynamicFormLoadBundleEvent('/admin/users/extended', pathParams: 'user-2'));
    await form.stream.firstWhere((s) => s is DynamicFormLoaded || s is DynamicFormFailure);
    form.add(const DynamicFormSubmitEvent({'email': 'alice@example.com', 'newPassword': 'Adm1nSet!Pw'}));
    await form.stream.firstWhere((s) => s is DynamicFormSubmitted || s is DynamicFormFailure);
    await Future.wait([login.close(), changePassword.close(), form.close()]);

    final entries = DevConsoleStore.instance.blocEntries;
    final recorded = [
      for (final entry in entries) '${entry.event} | ${entry.currentState} | ${entry.nextState}',
      TimeTravelStore.instance.exportAsJson(),
    ];
    expect(recorded, everyElement(allOf([for (final secret in secrets) isNot(contains(secret))])));
    // The tabs still name each event, so the flow can be followed.
    final events = entries.map((entry) => entry.event);
    for (final event in [
      'LoginFormSubmitted',
      'VerifyOtpSubmitted',
      'ChangePasswordChanged',
      'DynamicFormSubmitEvent',
    ]) {
      expect(events, anyElement(startsWith(event)));
    }
  });
}
