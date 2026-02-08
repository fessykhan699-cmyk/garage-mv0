import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:garage_mv0/models/customer.dart';
import 'package:garage_mv0/models/vehicle.dart';
import 'package:garage_mv0/models/job_card.dart';
import 'package:garage_mv0/repositories/mock/mock_customer_repository.dart';
import 'package:garage_mv0/repositories/mock/mock_vehicle_repository.dart';
import 'package:garage_mv0/repositories/mock/mock_job_card_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Repository Tests', () {
    late Box<Map<String, dynamic>> customerBox;
    late Box<Map<String, dynamic>> vehicleBox;
    late Box<Map<String, dynamic>> jobCardBox;

    setUp(() async {
      await Hive.initFlutter();
      
      customerBox = await Hive.openBox<Map<String, dynamic>>('test_customers');
      vehicleBox = await Hive.openBox<Map<String, dynamic>>('test_vehicles');
      jobCardBox = await Hive.openBox<Map<String, dynamic>>('test_job_cards');
      
      await customerBox.clear();
      await vehicleBox.clear();
      await jobCardBox.clear();
    });

    tearDown(() async {
      await customerBox.clear();
      await vehicleBox.clear();
      await jobCardBox.clear();
      await customerBox.close();
      await vehicleBox.close();
      await jobCardBox.close();
    });

    test('CustomerRepository - create and fetch', () async {
      final repo = MockCustomerRepository(customerBox: Future.value(customerBox));
      final now = DateTime.now();
      
      final customer = Customer(
        id: '',
        garageId: 'garage-123',
        createdAt: now,
        updatedAt: now,
      );

      final created = await repo.create(customer);
      expect(created.id, isNotEmpty);
      expect(created.garageId, 'garage-123');

      final fetched = await repo.fetch(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.id, created.id);
    });

    test('CustomerRepository - list by garage with sorting', () async {
      final repo = MockCustomerRepository(customerBox: Future.value(customerBox));
      final now = DateTime.now();
      
      // Create customers with different timestamps
      final customer1 = await repo.create(Customer(
        id: '',
        garageId: 'garage-123',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ));
      
      final customer2 = await repo.create(Customer(
        id: '',
        garageId: 'garage-123',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ));
      
      final customer3 = await repo.create(Customer(
        id: '',
        garageId: 'garage-123',
        createdAt: now,
        updatedAt: now,
      ));

      final customers = await repo.listByGarage('garage-123');
      expect(customers.length, 3);
      
      // Should be sorted by createdAt descending (newest first)
      expect(customers[0].id, customer3.id);
      expect(customers[1].id, customer2.id);
      expect(customers[2].id, customer1.id);
    });

    test('CustomerRepository - watch stream', () async {
      final repo = MockCustomerRepository(customerBox: Future.value(customerBox));
      final now = DateTime.now();
      
      final stream = repo.watchByGarage('garage-123');
      
      expect(
        stream,
        emitsInOrder([
          [],  // Initial empty list
          predicate<List<Customer>>((list) => list.length == 1),  // After first create
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      
      await repo.create(Customer(
        id: '',
        garageId: 'garage-123',
        createdAt: now,
        updatedAt: now,
      ));
    });

    test('VehicleRepository - create and list by customer', () async {
      final repo = MockVehicleRepository(vehicleBox: Future.value(vehicleBox));
      final now = DateTime.now();
      
      final vehicle = Vehicle(
        id: '',
        garageId: 'garage-123',
        customerId: 'customer-1',
        plateNumber: 'ABC-123',
        make: 'Toyota',
        model: 'Corolla',
        year: 2020,
        createdAt: now,
        updatedAt: now,
      );

      final created = await repo.create(vehicle);
      expect(created.id, isNotEmpty);

      final vehicles = await repo.listByCustomer('customer-1');
      expect(vehicles.length, 1);
      expect(vehicles[0].id, created.id);
      expect(vehicles[0].plateNumber, 'ABC-123');
    });

    test('JobCardRepository - create and list with sorting', () async {
      final repo = MockJobCardRepository(jobCardBox: Future.value(jobCardBox));
      final now = DateTime.now();
      
      // Create job cards with different timestamps
      final jobCard1 = await repo.create(JobCard(
        id: '',
        garageId: 'garage-123',
        customerId: 'customer-1',
        vehicleId: 'vehicle-1',
        jobCardNumber: 'JC-001',
        complaint: 'Oil change',
        status: JobCardStatus.draft,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
      ));
      
      final jobCard2 = await repo.create(JobCard(
        id: '',
        garageId: 'garage-123',
        customerId: 'customer-1',
        vehicleId: 'vehicle-1',
        jobCardNumber: 'JC-002',
        complaint: 'Brake check',
        status: JobCardStatus.draft,
        createdAt: now,
        updatedAt: now,
      ));

      final jobCards = await repo.listByGarage('garage-123');
      expect(jobCards.length, 2);
      
      // Should be sorted by createdAt descending (newest first)
      expect(jobCards[0].id, jobCard2.id);
      expect(jobCards[1].id, jobCard1.id);
    });

    test('Repository - filter by garageId', () async {
      final repo = MockCustomerRepository(customerBox: Future.value(customerBox));
      final now = DateTime.now();
      
      // Create customers for different garages
      await repo.create(Customer(
        id: '',
        garageId: 'garage-123',
        createdAt: now,
        updatedAt: now,
      ));
      
      await repo.create(Customer(
        id: '',
        garageId: 'garage-456',
        createdAt: now,
        updatedAt: now,
      ));

      final garage123Customers = await repo.listByGarage('garage-123');
      final garage456Customers = await repo.listByGarage('garage-456');

      expect(garage123Customers.length, 1);
      expect(garage456Customers.length, 1);
      expect(garage123Customers[0].garageId, 'garage-123');
      expect(garage456Customers[0].garageId, 'garage-456');
    });
  });
}
