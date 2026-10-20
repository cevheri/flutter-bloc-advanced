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
