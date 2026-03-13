import 'package:flutter_bloc_advance/features/settings/application/usecases/logout_settings_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LogoutSettingsUseCase useCase;

  setUp(() {
    useCase = const LogoutSettingsUseCase();
  });

  test('completes without error', () async {
    await expectLater(useCase.call(), completes);
  });
}
