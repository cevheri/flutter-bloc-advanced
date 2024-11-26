import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/menu.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/user_data.dart';

/// Test the menu model
void main() {
  // Initialize Test
  setUp(() {
    initializeJsonMapper();
  });

  group('Menu Model Tests', () {
    test('should create a Menu instance (Constructor)', () {
      const entity = mockMenuPayload;

      expect(entity.name, 'test name');
      expect(entity.description, '');
      expect(entity.url, 'https://dhw-api.onrender.com/');
      expect(entity.icon, '');
      expect(entity.orderPriority, 01);
      expect(entity.active, false);
      expect(entity.parent, null);
      expect(entity.level, 01);
    });

    test('should copy a Menu instance with new values (copyWith)', () {
      const entity = mockMenuPayload;
      final entityUpd = entity.copyWith(id: "0", name: 'Home');

      expect(entityUpd.id, "0");
      expect(entityUpd.name, 'Home');
      expect(entityUpd.description, '');
      expect(entityUpd.url, 'https://dhw-api.onrender.com/');
      expect(entityUpd.icon, '');
      expect(entityUpd.orderPriority, 01);
      expect(entityUpd.active, false);
      expect(entityUpd.parent, null);
      expect(entityUpd.level, 01);
    });

    test('should copy a Menu instance with copyWith just copy', () {
      const entity = mockMenuPayload;
      final entityUpd = entity.copyWith();

      expect(entityUpd.id, "0");
      expect(entityUpd.name, 'test name');
      expect(entityUpd.description, '');
      expect(entityUpd.url, 'https://dhw-api.onrender.com/');
      expect(entityUpd.icon, '');
      expect(entityUpd.orderPriority, 01);
      expect(entityUpd.active, false);
      expect(entityUpd.parent, null);
      expect(entityUpd.level, 01);
    });

    test('should deserialize from JSON', () {
      final json = mockMenuPayload.toJson();
      final entity = Menu.fromJson(json!);

      expect(entity?.name, 'test name');
      expect(entity?.description, '');
      expect(entity?.url, 'https://dhw-api.onrender.com/');
      expect(entity?.icon, '');
      expect(entity?.orderPriority, 01);
      expect(entity?.active, false);
      expect(entity?.parent, null);
      expect(entity?.level, 01);
    });

    test('should deserialize from JSON string', () {
      final jsonString = jsonEncode(mockMenuPayload.toJson()!);
      final entity = Menu.fromJsonString(jsonString);

      expect(entity?.name, 'test name');
      expect(entity?.description, '');
      expect(entity?.url, 'https://dhw-api.onrender.com/');
      expect(entity?.icon, '');
      expect(entity?.orderPriority, 01);
      expect(entity?.active, false);
      expect(entity?.parent, null);
      expect(entity?.level, 01);
    });
  });
}
