part of 'locale_cubit.dart';

/// Every state carries [locale], the language the app shows, because the app always shows one.
sealed class LocaleState extends Equatable {
  const LocaleState({required this.locale});

  final Locale locale;

  @override
  List<Object?> get props => [locale];
}

/// The stored language is being read at startup. Until it is, the app shows no page and [locale] is the configured
/// default.
final class LocaleRestoring extends LocaleState {
  const LocaleRestoring({required super.locale});
}

/// The app shows [locale]: the language the user picked, or the configured default when none is stored.
final class LocaleReady extends LocaleState {
  const LocaleReady({required super.locale});
}

/// [requested], the language the user picked, is being stored. The app shows [locale] until it is.
final class LocaleChanging extends LocaleState {
  const LocaleChanging({required super.locale, required this.requested});

  final Locale requested;

  @override
  List<Object?> get props => [locale, requested];
}

/// [requested] could not be stored, so the app still shows [locale]. The UI shows [errorCode] translated via
/// `errorCode.resolve(context)`.
final class LocaleChangeFailure extends LocaleState {
  const LocaleChangeFailure({required super.locale, required this.requested, required this.errorCode});

  final Locale requested;
  final AppErrorCode errorCode;

  @override
  List<Object?> get props => [locale, requested, errorCode];
}
