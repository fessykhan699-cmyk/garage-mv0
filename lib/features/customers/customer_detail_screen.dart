import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/customer.dart';
import '../../models/vehicle.dart';

final _customerDetailProvider =
    FutureProvider.autoDispose.family<Customer?, String>((ref, id) {
  return ref.watch(customersControllerProvider).fetch(id);
});

final _vehiclesByCustomerProvider =
    StreamProvider.autoDispose.family<List<Vehicle>, String>((ref, customerId) {
  return ref.watch(vehiclesControllerProvider).watchByCustomer(customerId);
});

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(_customerDetailProvider(customerId));
    final vehiclesAsync = ref.watch(_vehiclesByCustomerProvider(customerId));

    return AppScaffold(
      title: 'Customer Details',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('/customers/$customerId/edit'),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteCustomer(context, ref),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/customers/$customerId/vehicles/add'),
        icon: const Icon(Icons.directions_car_outlined),
        label: const Text('Add vehicle'),
      ),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(customer: customer),
              const SizedBox(height: 16),
              Text(
                'Vehicles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              vehiclesAsync.when(
                data: (vehicles) => vehicles.isEmpty
                    ? const Text('No vehicles added yet.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = vehicles[index];
                          return Card(
                            child: ListTile(
                              title: Text(vehicle.plateNumber),
                              subtitle: Text(_vehicleSubtitle(vehicle)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    context.go(
                                      '/customers/$customerId/vehicles/${vehicle.id}/edit',
                                    );
                                  }
                                  if (value == 'delete') {
                                    _deleteVehicle(context, ref, vehicle.id);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Error loading vehicles: $error'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  String _vehicleSubtitle(Vehicle vehicle) {
    final details = <String>[];
    if ((vehicle.make ?? '').isNotEmpty) details.add(vehicle.make!);
    if ((vehicle.model ?? '').isNotEmpty) details.add(vehicle.model!);
    if (vehicle.year != null) details.add(vehicle.year.toString());
    return details.isEmpty ? 'No details' : details.join(' • ');
  }

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref) async {
    await ref.read(customersControllerProvider).delete(customerId);
    if (context.mounted) {
      context.go('/customers');
    }
  }

  Future<void> _deleteVehicle(
    BuildContext context,
    WidgetRef ref,
    String vehicleId,
  ) async {
    await ref.read(vehiclesControllerProvider).delete(vehicleId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle deleted')),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name.isEmpty ? 'Customer ${customer.id}' : customer.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Phone: ${customer.phone.isEmpty ? 'N/A' : customer.phone}'),
            if ((customer.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${customer.notes}'),
            ],
          ],
        ),
      ),
    );
  }
}
