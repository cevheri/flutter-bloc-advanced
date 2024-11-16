import 'package:flutter_bloc_advance/data/models/authorities.dart';
import 'package:flutter_bloc_advance/data/models/change_password.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';

final DateTime createdDate = DateTime(2024, 1, 1);

User mockUserFullPayload = User(
  id: '1',
  login: 'test_login',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john.doe@example.com',
  activated: true,
  langKey: 'en',
  createdBy: 'admin',
  createdDate: createdDate,
  lastModifiedBy: 'admin',
  lastModifiedDate: createdDate,
  authorities: const ['ROLE_USER'],
);

Authorities mockAuthorityPayload = Authorities(
  name: 'ROLE_USER',
);

PasswordChangeDTO mockPasswordChangePayload = PasswordChangeDTO(
  currentPassword: 'password',
  newPassword: 'new_password',
);