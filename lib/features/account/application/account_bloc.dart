import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/update_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({
    GetAccountUseCase? getAccountUseCase,
    UpdateAccountUseCase? updateAccountUseCase,
    IAccountRepository? repository,
  }) : _getAccountUseCase =
           getAccountUseCase ?? GetAccountUseCase(repository ?? (throw ArgumentError('repository is required'))),
       _updateAccountUseCase =
           updateAccountUseCase ?? UpdateAccountUseCase(repository ?? (throw ArgumentError('repository is required'))),
       super(const AccountState()) {
    on<AccountEvent>((event, emit) {});
    on<AccountFetchEvent>(_onFetchAccount);
    on<AccountSubmitEvent>(_onSubmit);
  }

  static final _log = AppLogger.getLogger('AccountBloc');

  final GetAccountUseCase _getAccountUseCase;
  final UpdateAccountUseCase _updateAccountUseCase;

  FutureOr<void> _onFetchAccount(AccountFetchEvent event, Emitter<AccountState> emit) async {
    _log.debug('BEGIN: getAccount bloc: _onLoad');
    emit(state.copyWith(status: AccountStatus.loading));

    try {
      final user = await _getAccountUseCase();
      emit(state.copyWith(data: user, status: AccountStatus.success));
      _log.debug('END: getAccount bloc: _onLoad success: {}', [user.toString()]);
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      _log.error('END: getAccount bloc: _onLoad error: {}', [e.toString()]);
    }
  }

  FutureOr<void> _onSubmit(AccountSubmitEvent event, Emitter<AccountState> emit) async {
    _log.debug('BEGIN: onSubmit AccountSubmitEvent event: {}', [event.data.toString()]);
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      final user = await _updateAccountUseCase(event.data);
      emit(state.copyWith(status: AccountStatus.success, data: user));
      _log.debug('END:onSubmitAccountSubmitEvent event success: {}', [user.toString()]);
    } catch (e) {
      emit(state.copyWith(status: AccountStatus.failure));
      _log.error('END:onSubmit AccountSubmitEvent event error: {}', [e.toString()]);
    }
  }
}
