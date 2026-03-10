class ChangeLanguageUseCase {
  const ChangeLanguageUseCase();

  String call(String? language) {
    if (language == null || language.isEmpty) {
      throw ArgumentError('Language is required');
    }
    return language;
  }
}
