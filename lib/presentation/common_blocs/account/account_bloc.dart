import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';

import '../../../data/models/user.dart';
import '../../../data/repository/account_repository.dart';

part 'account_event.dart';
part 'account_state.dart';

/// Bloc responsible for managing the account.
/// It is used to load, update and delete the account.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  static final _log = AppLogger.getLogger("AccountBloc");
  final AccountRepository _repository;

  AccountBloc({required AccountRepository repository})
      : _repository = repository,
        super(const AccountState()) {
    on<AccountEvent>((event, emit) {});
    on<AccountFetchEvent>(_onFetchAccount);
  }

  /// Load the current account.
  FutureOr<void> _onFetchAccount(AccountFetchEvent event, Emitter<AccountState> emit) async {
    _log.debug("BEGIN: getAccount bloc: _onLoad");
    emit(state.copyWith(status: AccountStatus.loading));

    try {
      User user = await _repository.getAccount();
      await AppLocalStorage().save(StorageKeys.roles.name, user.authorities);
      await AppLocalStorage().save(StorageKeys.username.name, user.login);

      emit(state.copyWith(data: user, status: AccountStatus.success));
      _log.debug("END: getAccount bloc: _onLoad success: {}", [user.toString()]);
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      _log.error("END: getAccount bloc: _onLoad error: {}", [e.toString()]);
    }
  }
}
