import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/customer.dart';
import '../../models/job_card.dart';
import '../../models/vehicle.dart';

final _jobCardsProvider = StreamProvider.autoDispose<List<JobCard>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) return Stream.empty();
  return ref.watch(jobCardsControllerProvider).watchByGarage(garageId);
});

final _customersProvider = StreamProvider.autoDispose<List<Customer>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) return Stream.empty();
  return ref.watch(customersControllerProvider).watchByGarage(garageId);
});

final _vehiclesProvider = StreamProvider.autoDispose<List<Vehicle>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) return Stream.empty();
  return ref.watch(vehiclesControllerProvider).watchByGarage(garageId);
});

class JobCardsListScreen extends ConsumerWidget {
  const JobCardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobCards = ref.watch(_jobCardsProvider);
    final customers = ref.watch(_customersProvider).value ?? const [];
    final vehicles = ref.watch(_vehiclesProvider).value ?? const [];

    return AppScaffold(
      title: 'Job Cards',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/jobcards/add'),
        icon: const Icon(Icons.assignment_add_outlined),
        label: const Text('New job card'),
      ),
      body: jobCards.when(
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final jobCard = items[index];
                  final customerName = customers
                      .firstWhere(
                        (customer) => customer.id == jobCard.customerId,
                        orElse: () => Customer(
                          id: '',
                          garageId: '',
                          name: 'Unknown customer',
                          phone: '',
                          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
                        ),
                      )
                      .name;
                  final vehiclePlate = vehicles
                      .firstWhere(
                        (vehicle) => vehicle.id == jobCard.vehicleId,
                        orElse: () => Vehicle(
                          id: '',
                          garageId: '',
                          customerId: '',
                          plateNumber: 'Unknown vehicle',
                          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
                        ),
                      )
                      .plateNumber;
                  return Card(
                    child: ListTile(
                      title: Text(jobCard.jobCardNumber),
                      subtitle: Text(
                        '$customerName • $vehiclePlate\n${jobCard.complaint}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        _statusLabel(jobCard.status),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      onTap: () => context.go('/jobcards/${jobCard.id}'),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  String _statusLabel(JobCardStatus status) {
    switch (status) {
      case JobCardStatus.awaitingApproval:
        return 'Awaiting approval';
      case JobCardStatus.inProgress:
        return 'In progress';
      default:
        return status.name;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'No job cards yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a job card to track work and build quotations.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
