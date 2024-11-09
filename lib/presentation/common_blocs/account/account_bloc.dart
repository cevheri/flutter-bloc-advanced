import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/user.dart';
import '../../../data/repository/account_repository.dart';
import '../../../utils/storage.dart';

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

    try {
      User user = await _accountRepository.getAccount();
      saveStorage(username: user.login!);
      saveStorage(roles: user.authorities);
      loadStorageData();
      emit(state.copyWith(
        account: user,
        status: AccountStatus.success,
      ));
      log("AccountBloc._onLoad end : ${state.account}, ${state.status}");
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      log("AccountBloc._onLoad error : ${state.props}. error-detail: $e");
    }
  }
}
