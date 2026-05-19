import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/update_account_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({required GetAccountUseCase getAccountUseCase, required UpdateAccountUseCase updateAccountUseCase})
    : _getAccountUseCase = getAccountUseCase,
      _updateAccountUseCase = updateAccountUseCase,
      super(const AccountState()) {
    on<AccountFetchEvent>(_onFetchAccount, transformer: EventTransformers.restart());
    on<AccountSubmitEvent>(_onSubmit, transformer: EventTransformers.dropConcurrent());
  }

  static final _log = AppLogger.getLogger('AccountBloc');

  final GetAccountUseCase _getAccountUseCase;
  final UpdateAccountUseCase _updateAccountUseCase;

  FutureOr<void> _onFetchAccount(AccountFetchEvent event, Emitter<AccountState> emit) async {
    _log.debug('BEGIN: getAccount bloc: _onLoad');
    emit(state.copyWith(status: AccountStatus.loading));

    final result = await _getAccountUseCase();
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(data: data, status: AccountStatus.success));
        _log.debug('END: getAccount bloc: _onLoad success: {}', [data.toString()]);
      case Failure(:final error):
        emit(state.copyWith(status: AccountStatus.failure));
        _log.error('END: getAccount bloc: _onLoad error: {}', [error.toString()]);
    }
  }

  FutureOr<void> _onSubmit(AccountSubmitEvent event, Emitter<AccountState> emit) async {
    _log.debug('BEGIN: onSubmit AccountSubmitEvent event: {}', [event.data.toString()]);
    emit(state.copyWith(status: AccountStatus.loading));

    final result = await _updateAccountUseCase(event.data);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: AccountStatus.success, data: data));
        _log.debug('END:onSubmitAccountSubmitEvent event success: {}', [data.toString()]);
      case Failure(:final error):
        emit(state.copyWith(status: AccountStatus.failure));
        _log.error('END:onSubmit AccountSubmitEvent event error: {}', [error.toString()]);
    }
  }
}
