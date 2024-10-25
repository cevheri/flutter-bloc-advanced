import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/user.dart';
import '../../../data/repository/account_repository.dart';

part 'account_event.dart';
part 'account_state.dart';

/// Bloc responsible for managing the account.
/// It is used to load, update and delete the account.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _accountRepository;

  AccountBloc({required AccountRepository accountRepository})
      : _accountRepository = accountRepository,
        super(const AccountState()) {
    on<AccountEvent>((event, emit) {});
    on<AccountLoad>(_onLoad);
  }

  /// Load the current account.
  FutureOr<void> _onLoad(AccountLoad event, Emitter<AccountState> emit) async {
    log("AccountBloc._onLoad start : ${event.props}, $emit");
    emit(state.copyWith(status: AccountStatus.loading));
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      User user = await _accountRepository.getAccount();
      //TODO will be deleted after test mock data
      // await _accountRepository.register(user);
      // await _accountRepository.changePassword(PasswordChangeDTO(currentPassword: '1', newPassword: '2'));
      // await _accountRepository.resetPassword('mailAddress');
      // await _accountRepository.saveAccount(user);
      // await _accountRepository.updateAccount(user);
      // await _accountRepository.deleteAccount(user.id!);

      await prefs.setString('username', user.login!);
      await prefs.setString('role', user.authorities![0]);

      emit(state.copyWith(
        account: user,
        status: AccountStatus.success,
      ));
      log("AccountBloc._onLoad end : ${state.account}, ${state.status}");
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      log("AccountBloc._onLoad error : ${state.account}, ${state.status} error: $e");
    }
  }
}
