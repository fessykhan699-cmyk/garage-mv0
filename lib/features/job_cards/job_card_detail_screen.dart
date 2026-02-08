import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/customer.dart';
import '../../models/job_card.dart';
import '../../models/quotation.dart';
import '../../models/vehicle.dart';

final _jobCardProvider =
    StreamProvider.autoDispose.family<JobCard?, String>((ref, id) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) {
    return Stream<JobCard?>.empty();
  }
  return ref
      .watch(jobCardsControllerProvider)
      .watchByGarage(garageId)
      .map((items) => _findById(items, id));
});

final _quotationsProvider =
    StreamProvider.autoDispose.family<List<Quotation>, String>((ref, garageId) {
  return ref.watch(quotationControllerProvider).watchByGarage(garageId);
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

class JobCardDetailScreen extends ConsumerStatefulWidget {
  const JobCardDetailScreen({super.key, required this.jobCardId});

  final String jobCardId;

  @override
  ConsumerState<JobCardDetailScreen> createState() => _JobCardDetailScreenState();
}

class _JobCardDetailScreenState extends ConsumerState<JobCardDetailScreen> {
  final _afterPhotosController = TextEditingController();
  JobCardStatus? _status;
  bool _loaded = false;

  @override
  void dispose() {
    _afterPhotosController.dispose();
    super.dispose();
  }

  void _load(JobCard jobCard) {
    if (_loaded) return;
    _afterPhotosController.text = jobCard.afterPhotoPaths.join(', ');
    _status = jobCard.status;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final jobCardAsync = ref.watch(_jobCardProvider(widget.jobCardId));
    final customers = ref.watch(_customersProvider).value ?? const [];
    final vehicles = ref.watch(_vehiclesProvider).value ?? const [];
    final garageId = ref.watch(activeGarageIdProvider);
    final quotationsAsync = garageId == null
        ? const AsyncValue<List<Quotation>>.data([])
        : ref.watch(_quotationsProvider(garageId));

    return AppScaffold(
      title: 'Job Card',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteJobCard(context),
        ),
        TextButton(
          onPressed: () => _save(jobCardAsync.value),
          child: const Text('Save'),
        ),
      ],
      body: jobCardAsync.when(
        data: (jobCard) {
          if (jobCard == null) {
            return const Center(child: Text('Job card not found'));
          }
          _load(jobCard);
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
          final quotation = quotationsAsync.maybeWhen(
            data: (quotes) => _findQuotation(quotes, jobCard.id),
            orElse: () => null,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                jobCard.jobCardNumber,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Customer: $customerName'),
              Text('Vehicle: $vehiclePlate'),
              const SizedBox(height: 16),
              Text(
                'Complaint',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(jobCard.complaint),
              if ((jobCard.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Notes: ${jobCard.notes}'),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<JobCardStatus>(
                value: _status ?? jobCard.status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: JobCardStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _afterPhotosController,
                decoration: const InputDecoration(
                  labelText: 'After photo paths (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _PhotoList(
                title: 'Before Photos',
                paths: jobCard.beforePhotoPaths,
              ),
              const SizedBox(height: 12),
              _PhotoList(
                title: 'After Photos',
                paths: jobCard.afterPhotoPaths,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _handleQuotation(context, jobCard, quotation),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(
                  quotation == null ? 'Create quotation' : 'View quotation',
                ),
              ),
            ],
          );
        },
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

  Future<void> _save(JobCard? jobCard) async {
    if (jobCard == null) return;
    final updated = JobCard(
      id: jobCard.id,
      garageId: jobCard.garageId,
      customerId: jobCard.customerId,
      vehicleId: jobCard.vehicleId,
      jobCardNumber: jobCard.jobCardNumber,
      complaint: jobCard.complaint,
      notes: jobCard.notes,
      beforePhotoPaths: jobCard.beforePhotoPaths,
      afterPhotoPaths: _afterPhotosController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      status: _status ?? jobCard.status,
      createdAt: jobCard.createdAt,
      updatedAt: DateTime.now(),
    );
    await ref.read(jobCardsControllerProvider).update(updated);
  }

  Future<void> _handleQuotation(
    BuildContext context,
    JobCard jobCard,
    Quotation? existing,
  ) async {
    if (existing != null) {
      context.go('/quotations/${existing.id}');
      return;
    }
    final now = DateTime.now();
    final quotation = await ref.read(quotationControllerProvider).create(
          garageId: jobCard.garageId,
          jobCardId: jobCard.id,
          customerId: jobCard.customerId,
          vehicleId: jobCard.vehicleId,
          quoteNumber: 'QT-${now.millisecondsSinceEpoch}',
        );
    if (context.mounted) {
      context.go('/quotations/${quotation.id}/builder');
    }
  }

  Future<void> _deleteJobCard(BuildContext context) async {
    await ref.read(jobCardsControllerProvider).delete(widget.jobCardId);
    if (context.mounted) {
      context.go('/jobcards');
    }
  }
}

class _PhotoList extends StatelessWidget {
  const _PhotoList({required this.title, required this.paths});

  final String title;
  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (paths.isEmpty)
          const Text('No photos yet.')
        else
          Wrap(
            spacing: 8,
            children: paths.map((path) => Chip(label: Text(path))).toList(),
          ),
      ],
    );
  }
}

JobCard? _findById(List<JobCard> items, String id) {
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}

Quotation? _findQuotation(List<Quotation> quotes, String jobCardId) {
  for (final quote in quotes) {
    if (quote.jobCardId == jobCardId) return quote;
  }
  return null;
}
