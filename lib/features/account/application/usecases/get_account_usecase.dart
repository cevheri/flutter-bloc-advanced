import 'package:flutter_bloc_advance/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class GetAccountUseCase {
  const GetAccountUseCase(this._repository);

  final IAccountRepository _repository;

  Future<UserEntity> call() {
    return _repository.getAccount();
  }
}
