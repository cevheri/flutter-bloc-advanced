import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/user.dart';
import '../../../../data/repository/account_repository.dart';

part 'settings_event.dart';

part 'settings_state.dart';

/// Bloc responsible for managing the settings.
/// It is used to loadCurrentUser and update the settings.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required AccountRepository accountRepository,
  })  : _accountRepository = accountRepository,
        super(const SettingsState()) {
    on<SettingsEvent>((event, emit) {});
    on<SettingsLoadCurrentUser>(_onLoadCurrentUser);
    on<SettingsFirstNameChanged>(_firstNameChanged);
    on<SettingsLastNameChanged>(_lastNameChanged);
    on<SettingsEmailChanged>(_emailChanged);
    on<SettingsLanguageChanged>(_languageChanged);
    on<SettingsFormSubmitted>(_onSubmit);
  }

  final AccountRepository _accountRepository;

  /// Load the current user.
  FutureOr<void> _onLoadCurrentUser(SettingsLoadCurrentUser event, Emitter<SettingsState> emit) async {
    log('event value: $event, emit $emit');
    emit(state.copyWith(status: SettingsStatus.loading));
    log('state value: ${state.firstName}, ${state.lastName}, ${state.email}, ${state.language}, ${state.status}');
    try {
      User user = await _accountRepository.getAccount();

      emit(state.copyWith(
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        language: user.langKey,
        status: SettingsStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.failure));
      log("state values: ${state.firstName}, ${state.lastName}, ${state.email}, ${state.language}, ${state.status}");
      log('error: $e');
    }
  }

  FutureOr<void> _firstNameChanged(SettingsFirstNameChanged event, Emitter<SettingsState> emit) {
    log('event value: ${event.firstName}, emit $emit');
    state.copyWith(firstName: event.firstName);
    log('state value: ${state.firstName}, ${state.lastName}, ${state.email}, ${state.language}, ${state.status}');
  }

  FutureOr<void> _lastNameChanged(SettingsLastNameChanged event, Emitter<SettingsState> emit) {
    log('event value: ${event.lastName}, emit $emit');
    state.copyWith(lastName: event.lastName);
    log('state value: ${state.firstName}, ${state.lastName}, ${state.email}, ${state.language}, ${state.status}');
  }

  FutureOr<void> _emailChanged(SettingsEmailChanged event, Emitter<SettingsState> emit) {
    log('event value: ${event.email}, emit $emit');
    state.copyWith(email: event.email);
    log('state value: ${state.firstName}, ${state.lastName}, ${state.email}, ${state.language}, ${state.status}');
  }

  FutureOr<void> _languageChanged(SettingsLanguageChanged event, Emitter<SettingsState> emit) {
    log('event value: ${event.language}, emit $emit');
    state.copyWith(language: event.language);
    log('state value: ${state.firstName}, ${state.lastName}, ${state.email}, ${state.language}, ${state.status}');
  }

  FutureOr<void> _onSubmit(SettingsFormSubmitted event, Emitter<SettingsState> emit) async {
    log('event value: $event, emit $emit');
    state.copyWith(status: SettingsStatus.loading);
    log('state value: ${state.firstName}, ${state.lastName}, ${state.email}, ${state.language}, ${state.status}');
    try {
      User user = User(
        firstName: state.firstName,
        lastName: state.lastName,
        email: state.email,
        langKey: state.language,
      );
      await _accountRepository.saveAccount(user);
      state.copyWith(status: SettingsStatus.loaded);
    } catch (e) {
      state.copyWith(status: SettingsStatus.failure);
      log('error: $e');
    }
  }
}
