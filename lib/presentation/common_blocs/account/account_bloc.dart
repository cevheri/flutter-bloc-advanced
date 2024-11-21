import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';

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
    debugPrint("BEGIN: getAccount bloc: _onLoad");
    log("AccountBloc._onLoad start : ${event.props}, $emit");
    emit(state.copyWith(status: AccountStatus.loading));

    try {
      User user = await _accountRepository.getAccount();
      await AppLocalStorage().save(StorageKeys.roles.name, user.authorities);
      await AppLocalStorage().save(StorageKeys.username.name, user.login);

      emit(state.copyWith(account: user, status: AccountStatus.success));
      log("AccountBloc._onLoad end : ${state.account}, ${state.status}");
      debugPrint("END: getAccount bloc: _onLoad");
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      log("AccountBloc._onLoad error : ${state.props}. error-detail: $e");
    }
  }
}
