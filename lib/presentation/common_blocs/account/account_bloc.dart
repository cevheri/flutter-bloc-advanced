import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';

import '../../../data/models/user.dart';
import '../../../data/repository/account_repository.dart';

part 'account_event.dart';

part 'account_state.dart';

/// Bloc responsible for managing the account.
/// It is used to load, update and delete the account.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  static final _log = AppLogger.getLogger("AccountBloc");
  final AccountRepository _repository;

  AccountBloc({required AccountRepository repository}) : _repository = repository, super(const AccountState()) {
    on<AccountEvent>((event, emit) {});
    on<AccountFetchEvent>(_onFetchAccount);
    on<AccountSubmitEvent>(_onSubmit);
  }

  /// Load the current account.
  FutureOr<void> _onFetchAccount(AccountFetchEvent event, Emitter<AccountState> emit) async {
    _log.debug("BEGIN: getAccount bloc: _onLoad");
    emit(state.copyWith(status: AccountStatus.loading));

    try {
      User user = await _repository.getAccount();
      emit(state.copyWith(data: user, status: AccountStatus.success));
      _log.debug("END: getAccount bloc: _onLoad success: {}", [user.toString()]);
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      _log.error("END: getAccount bloc: _onLoad error: {}", [e.toString()]);
    }
  }

  FutureOr<void> _onSubmit(AccountSubmitEvent event, Emitter<AccountState> emit) async {
    _log.debug("BEGIN: onSubmit AccountSubmitEvent event: {}", [event.data.toString()]);
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      final user = await _repository.update(event.data);
      emit(state.copyWith(status: AccountStatus.success, data: user));
      _log.debug("END:onSubmitAccountSubmitEvent event success: {}", [user.toString()]);
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      _log.error("END:onSubmit AccountSubmitEvent event error: {}", [e.toString()]);
    }
  }
}
