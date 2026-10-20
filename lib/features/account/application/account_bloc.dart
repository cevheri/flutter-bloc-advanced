import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/get_account_usecase.dart';
import 'package:flutter_bloc_advance/features/account/application/usecases/update_account_usecase.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/utils/event_transformers.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({required this._getAccountUseCase, required this._updateAccountUseCase}) : super(const AccountState()) {
    on<AccountFetchEvent>(_onFetchAccount, transformer: EventTransformers.restart());
    on<AccountSubmitEvent>(_onSubmit, transformer: EventTransformers.dropConcurrent());
    on<AccountResetEvent>(_onReset);
  }

  static final _log = AppLogger.getLogger('AccountBloc');

  final GetAccountUseCase _getAccountUseCase;
  final UpdateAccountUseCase _updateAccountUseCase;

  /// How many times the account was reset. A fetch or a save drops its result when this changed while its request
  /// was out, so the account of a session that has ended does not come back.
  int _resets = 0;

  FutureOr<void> _onFetchAccount(AccountFetchEvent event, Emitter<AccountState> emit) async {
    _log.debug('BEGIN: getAccount bloc: _onLoad');
    final resets = _resets;
    emit(state.copyWith(status: AccountStatus.loading));

    final result = await _getAccountUseCase();
    if (resets != _resets) {
      _log.debug('END: getAccount bloc: _onLoad result dropped, the account was reset meanwhile');
      return;
    }
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(data: data, status: AccountStatus.success));
        _log.debug('END: getAccount bloc: _onLoad success: {}', [data]);
      case Failure(:final error):
        emit(state.copyWith(status: AccountStatus.failure, errorCode: AppErrorCode.fromKey(error.code)));
        _log.error('END: getAccount bloc: _onLoad error: {}', [error]);
    }
  }

  FutureOr<void> _onSubmit(AccountSubmitEvent event, Emitter<AccountState> emit) async {
    _log.debug('BEGIN: onSubmit AccountSubmitEvent event: {}', [event.data]);
    final resets = _resets;
    emit(state.copyWith(status: AccountStatus.loading));

    final result = await _updateAccountUseCase(event.data);
    if (resets != _resets) {
      _log.debug('END:onSubmit AccountSubmitEvent result dropped, the account was reset meanwhile');
      return;
    }
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: AccountStatus.success, data: data));
        _log.debug('END:onSubmitAccountSubmitEvent event success: {}', [data]);
      case Failure(:final error):
        emit(state.copyWith(status: AccountStatus.failure, errorCode: AppErrorCode.fromKey(error.code)));
        _log.error('END:onSubmit AccountSubmitEvent event error: {}', [error]);
    }
  }

  void _onReset(AccountResetEvent event, Emitter<AccountState> emit) {
    _resets++;
    emit(const AccountState());
  }
}
