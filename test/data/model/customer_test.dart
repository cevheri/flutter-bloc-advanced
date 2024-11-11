import 'package:flutter_bloc_advance/data/models/customer.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Customer customerModel;

  Customer initCustomer() {
    return Customer(
      id: '1',
      name: 'Acme',
      phone: '5055055050',
      cityName: 'Konya',
      email: 'john.doe@example.com',
      districtName: 'selçuklu',
      address: 'yazır mh.',
      active: true,
    );
  }

  setUp(() {
    initializeJsonMapper();

    customerModel = initCustomer();
  });

  group("Customer model", () {
    test("should create a Customer instance (Constructor)", () {
      final finalCustomer = customerModel;

      expect(finalCustomer.id, '1');
      expect(finalCustomer.name, 'Acme');
      expect(finalCustomer.phone, '5055055050');
      expect(finalCustomer.cityName, 'Konya');
      expect(finalCustomer.email, 'john.doe@example.com');
      expect(finalCustomer.districtName, "selçuklu");
      expect(finalCustomer.address, 'yazır mh.');
      expect(finalCustomer.active, true);
    });

    test('should copy a Customer instance with new values (copyWith)', () {
      final finalCustomer = customerModel;

      final updatedCustomer = finalCustomer.copyWith(
        name: 'new Acme',
        cityName: 'izmir',
        districtName: 'göztepe',
        address: 'yazır',
      );

      expect(updatedCustomer.id, '1');
      expect(updatedCustomer.name, 'new Acme');
      expect(updatedCustomer.phone, '5055055050');
      expect(updatedCustomer.cityName, 'izmir');
      expect(updatedCustomer.email, 'john.doe@example.com');
      expect(updatedCustomer.districtName, 'göztepe');
      expect(updatedCustomer.address, 'yazır');
      expect(updatedCustomer.active, true);
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': '1',
        'name': 'Acme',
        'phone': '5055055050',
        'cityName': 'Konya',
        'email': 'john.doe@example.com',
        'districtName': 'selçuklu',
        'address': 'yazır mh.',
        'active': true,
      };

      final finalCustomer = Customer.fromJson(json);

      expect(finalCustomer?.id, '1');
      expect(finalCustomer?.name, 'Acme');
      expect(finalCustomer?.phone, '5055055050');
      expect(finalCustomer?.cityName, 'Konya');
      expect(finalCustomer?.email, 'john.doe@example.com');
      expect(finalCustomer?.districtName, "selçuklu");
      expect(finalCustomer?.address, 'yazır mh.');
      expect(finalCustomer?.active, true);
    });

    test('should deserialize from JSON string', () {
      final jsonString = '''
       {
         "id": "1",                      
         "name" : "Acme",       
         "phone" : "5055055050",         
         "cityName": "izmir",            
         "email": "john.doe@example.com",
         "districtName": "göztepe",     
         "address": "yazır",         
         "active": true
       }
       ''';

      final finalCustomer = Customer.fromJsonString(jsonString);

      expect(finalCustomer?.id, '1');
      expect(finalCustomer?.name, 'Acme');
      expect(finalCustomer?.phone, '5055055050');
      expect(finalCustomer?.cityName, 'izmir');
      expect(finalCustomer?.email, 'john.doe@example.com');
      expect(finalCustomer?.districtName, "göztepe");
      expect(finalCustomer?.address, 'yazır');
      expect(finalCustomer?.active, true);
    });
  });
}
