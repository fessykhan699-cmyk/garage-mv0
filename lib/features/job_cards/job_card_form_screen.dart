import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/customer.dart';
import '../../models/job_card.dart';
import '../../models/vehicle.dart';

final _customersProvider = StreamProvider.autoDispose<List<Customer>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) return Stream.empty();
  return ref.watch(customersControllerProvider).watchByGarage(garageId);
});

final _vehiclesForCustomerProvider =
    StreamProvider.autoDispose.family<List<Vehicle>, String>((ref, customerId) {
  return ref.watch(vehiclesControllerProvider).watchByCustomer(customerId);
});

class JobCardFormScreen extends ConsumerStatefulWidget {
  const JobCardFormScreen({super.key});

  @override
  ConsumerState<JobCardFormScreen> createState() => _JobCardFormScreenState();
}

class _JobCardFormScreenState extends ConsumerState<JobCardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _complaintController = TextEditingController();
  final _notesController = TextEditingController();
  final _beforePhotosController = TextEditingController();
  String? _selectedCustomerId;
  String? _selectedVehicleId;

  @override
  void dispose() {
    _complaintController.dispose();
    _notesController.dispose();
    _beforePhotosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(_customersProvider);
    final vehicles = _selectedCustomerId == null
        ? const AsyncValue<List<Vehicle>>.data([])
        : ref.watch(_vehiclesForCustomerProvider(_selectedCustomerId!));

    return AppScaffold(
      title: 'Create Job Card',
      actions: [
        TextButton(
          onPressed: () => _submit(context),
          child: const Text('Save'),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              customers.when(
                data: (items) => DropdownButtonFormField<String>(
                  value: _selectedCustomerId,
                  items: items
                      .map(
                        (customer) => DropdownMenuItem(
                          value: customer.id,
                          child: Text(
                            customer.name.isEmpty
                                ? 'Customer ${customer.id}'
                                : customer.name,
                          ),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Customer',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedCustomerId = value;
                      _selectedVehicleId = null;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a customer' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Error loading customers: $error'),
              ),
              const SizedBox(height: 16),
              vehicles.when(
                data: (items) => DropdownButtonFormField<String>(
                  value: _selectedVehicleId,
                  items: items
                      .map(
                        (vehicle) => DropdownMenuItem(
                          value: vehicle.id,
                          child: Text(vehicle.plateNumber),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Vehicle',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {
                    _selectedVehicleId = value;
                  }),
                  validator: (value) =>
                      value == null ? 'Select a vehicle' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Error loading vehicles: $error'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _complaintController,
                decoration: const InputDecoration(
                  labelText: 'Complaint',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter complaint';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _beforePhotosController,
                decoration: const InputDecoration(
                  labelText: 'Before photo paths (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) return;
    final garageId = ref.read(activeGarageIdProvider);
    if (garageId == null || garageId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No garage selected')),
      );
      return;
    }
    final now = DateTime.now();
    final beforePhotos = _beforePhotosController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final jobCard = JobCard(
      id: '',
      garageId: garageId,
      customerId: _selectedCustomerId!,
      vehicleId: _selectedVehicleId!,
      jobCardNumber: 'JC-${now.millisecondsSinceEpoch}',
      complaint: _complaintController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      beforePhotoPaths: beforePhotos,
      status: JobCardStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final created = await ref.read(jobCardsControllerProvider).create(jobCard);
      if (context.mounted) {
        context.go('/jobcards/${created.id}');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create job card: $error')),
        );
      }
    }
  }
}
