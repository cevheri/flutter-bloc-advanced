import 'package:flutter_bloc_advance/data/models/authority.dart';
import 'package:flutter_bloc_advance/data/models/change_password.dart';
import 'package:flutter_bloc_advance/data/models/jwt_token.dart';
import 'package:flutter_bloc_advance/data/models/menu.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/models/user_jwt.dart';

final DateTime createdDate = DateTime(2024, 1, 1);

/// User fake data with full payload
final mockUserFullPayload = User(
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

/// Authority(Role) fake data
const mockAuthorityPayload = Authority(name: 'ROLE_USER');

/// PasswordChange fake data with full payload
const mockPasswordChangePayload = PasswordChangeDTO(currentPassword: 'password', newPassword: 'new_password');

/// JWTToken fake data
const mockJWTTokenPayload = JWTToken(idToken: 'MOCK_TOKEN');

/// Menu fake data with full payload
const mockMenuPayload = Menu(
  id: "0",
  name: 'test name',
  description: '',
  url: 'https://dhw-api.onrender.com/',
  icon: '',
  orderPriority: 01,
  active: false,
  parent: null,
  level: 01,
);

/// UserJWT fake data with full payload
const mockUserJWTPayload = UserJWT("username", "password");
