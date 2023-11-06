import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';

import '../../../data/models/user.dart';
import '../../../data/repository/account_repository.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:dart_json_mapper/dart_json_mapper.dart';

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
    on<AccountUpdate>(_onUpdate);
    on<AccountDelete>(_onDelete);
  }

  // get account from local json
  Future<User> _getUserFromLocal() async {
    try {
      // read json file from ./mock/users.json
      // String content = await File('assets/mock/users.json').readAsString();
      String content = await rootBundle.loadString('assets/mock/users.json');
      // deserialize json to User object
      return JsonMapper.deserialize<User>(content)!;
    } catch (e) {
      log("AccountBloc._getUserFromLocal error : $e");
      return User();
    }
  }

  /// Load the current account.
  FutureOr<void> _onLoad(AccountLoad event, Emitter<AccountState> emit) async {
    log("AccountBloc._onLoad 1 start : $event");
    emit(state.copyWith(account: User(), status: AccountStatus.loading));
    User user = User();
    try {

      if (ProfileConstants.isDevelopment) {
        user = await _getUserFromLocal();
      } else {
        user = await _accountRepository.getAccount();
      }

      log("AccountBloc._onLoad 2 user : $user");
      emit(state.copyWith(
        account: user,
        status: AccountStatus.success,
      ));

      log("AccountBloc._onLoad 3 end : ${state.account}, ${state.status}");

    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      log("AccountBloc._onLoad ERROR :$e");
    }
  }

  FutureOr<void> _onUpdate(AccountUpdate event, Emitter<AccountState> emit) async {
    log("AccountBloc._onUpdate start : ${event.props}, $emit");
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      User user = await _accountRepository.updateAccount(event.account);
      emit(state.copyWith(
        account: user,
        status: AccountStatus.success,
      ));
      log("AccountBloc._onUpdate end : ${state.account}, ${state.status}");
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      log("AccountBloc._onUpdate error : ${state.account}, ${state.status}");
    }
  }

  FutureOr<void> _onDelete(AccountDelete event, Emitter<AccountState> emit) async {
    log("AccountBloc._onDelete start : ${event.props}, $emit");
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      await _accountRepository.deleteAccount();
      emit(state.copyWith(
        account: User(),
        status: AccountStatus.success,
      ));
      log("AccountBloc._onDelete end : ${state.account}, ${state.status}");
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      log("AccountBloc._onDelete error : ${state.account}, ${state.status}");
    }
  }
}
