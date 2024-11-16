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
      final finalMenu = menuMockPayload;
      expect(finalMenu.name, 'test name');
      expect(finalMenu.description, '');
      expect(finalMenu.url, 'https://dhw-api.onrender.com/');
      expect(finalMenu.icon, '');
      expect(finalMenu.orderPriority, 01);
      expect(finalMenu.active, false);
      expect(finalMenu.parent, null);
      expect(finalMenu.level, 01);
    });

    test('should copy a Menu instance with new values (copyWith)', () {
      final finalMenu = menuMockPayload;
      final updatedMenu = finalMenu.copyWith(
        id: 0,
        name: 'Home',
      );

      expect(updatedMenu.id, 0);
      expect(updatedMenu.name, 'Home');
      expect(updatedMenu.description, '');
      expect(updatedMenu.url, 'https://dhw-api.onrender.com/');
      expect(updatedMenu.icon, '');
      expect(updatedMenu.orderPriority, 01);
      expect(updatedMenu.active, false);
      expect(updatedMenu.parent, null);
      expect(updatedMenu.level, 01);
    });

    test('should deserialize from JSON', () {
      final json = menuMockPayload.toJson();

      final finalMenu = Menu.fromJson(json!);

      expect(finalMenu?.name, 'test name');
      expect(finalMenu?.description, '');
      expect(finalMenu?.url, 'https://dhw-api.onrender.com/');
      expect(finalMenu?.icon, '');
      expect(finalMenu?.orderPriority, 01);
      expect(finalMenu?.active, false);
      expect(finalMenu?.parent, null);
      expect(finalMenu?.level, 01);
    });

    test('should deserialize from JSON string', () {
      final jsonString = jsonEncode(menuMockPayload.toJson()!);

      final finalMenu = Menu.fromJsonString(jsonString);

      expect(finalMenu?.name, 'test name');
      expect(finalMenu?.description, '');
      expect(finalMenu?.url, 'https://dhw-api.onrender.com/');
      expect(finalMenu?.icon, '');
      expect(finalMenu?.orderPriority, 01);
      expect(finalMenu?.active, false);
      expect(finalMenu?.parent, null);
      expect(finalMenu?.level, 01);
    });
  });
}
