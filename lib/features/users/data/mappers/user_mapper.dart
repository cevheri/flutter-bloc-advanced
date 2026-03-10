import 'package:flutter_bloc_advance/features/users/data/models/user.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class UserMapper {
  const UserMapper._();

  static UserEntity toEntity(User model) {
    return UserEntity(
      id: model.id,
      login: model.login,
      firstName: model.firstName,
      lastName: model.lastName,
      email: model.email,
      activated: model.activated,
      langKey: model.langKey,
      createdBy: model.createdBy,
      createdDate: model.createdDate,
      lastModifiedBy: model.lastModifiedBy,
      lastModifiedDate: model.lastModifiedDate,
      authorities: model.authorities,
    );
  }

  static User toModel(UserEntity entity) {
    return User(
      id: entity.id,
      login: entity.login,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      activated: entity.activated,
      langKey: entity.langKey,
      createdBy: entity.createdBy,
      createdDate: entity.createdDate,
      lastModifiedBy: entity.lastModifiedBy,
      lastModifiedDate: entity.lastModifiedDate,
      authorities: entity.authorities,
    );
  }

  static List<UserEntity> toEntityList(List<User> models) {
    return models.map(toEntity).toList(growable: false);
  }
}
