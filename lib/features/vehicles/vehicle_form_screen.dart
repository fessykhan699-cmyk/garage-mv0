import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/vehicle.dart';

final _vehicleProvider =
    FutureProvider.autoDispose.family<Vehicle?, String>((ref, id) {
  return ref.watch(vehiclesControllerProvider).fetch(id);
});

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.customerId, this.vehicleId});

  final String? customerId;
  final String? vehicleId;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _load(Vehicle vehicle) {
    if (_loaded) return;
    _plateController.text = vehicle.plateNumber;
    _makeController.text = vehicle.make ?? '';
    _modelController.text = vehicle.model ?? '';
    _yearController.text = vehicle.year?.toString() ?? '';
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicleId != null;
    final vehicleAsync = isEditing
        ? ref.watch(_vehicleProvider(widget.vehicleId!))
        : const AsyncValue<Vehicle?>.data(null);

    return AppScaffold(
      title: isEditing ? 'Edit Vehicle' : 'Add Vehicle',
      actions: [
        TextButton(
          onPressed: () => _submit(context, isEditing),
          child: const Text('Save'),
        ),
      ],
      body: vehicleAsync.when(
        data: (vehicle) {
          if (vehicle != null) _load(vehicle);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: 'Plate number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter plate number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(
                      labelText: 'Make (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Year (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _submit(BuildContext context, bool isEditing) async {
    if (_formKey.currentState?.validate() != true) return;
    final garageId = ref.read(activeGarageIdProvider);
    final customerId = widget.customerId;
    if (garageId == null || garageId.isEmpty || customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing garage or customer')),
      );
      return;
    }
    final now = DateTime.now();
    final controller = ref.read(vehiclesControllerProvider);
    final year = int.tryParse(_yearController.text.trim());
    try {
      if (isEditing) {
        final existing = await controller.fetch(widget.vehicleId!);
        if (existing == null) {
          throw StateError('Vehicle not found');
        }
        final updated = Vehicle(
          id: existing.id,
          garageId: existing.garageId,
          customerId: existing.customerId,
          plateNumber: _plateController.text.trim(),
          make: _makeController.text.trim().isEmpty
              ? null
              : _makeController.text.trim(),
          model: _modelController.text.trim().isEmpty
              ? null
              : _modelController.text.trim(),
          year: year,
          createdAt: existing.createdAt,
          updatedAt: now,
        );
        await controller.update(updated);
      } else {
        final created = Vehicle(
          id: '',
          garageId: garageId,
          customerId: customerId,
          plateNumber: _plateController.text.trim(),
          make: _makeController.text.trim().isEmpty
              ? null
              : _makeController.text.trim(),
          model: _modelController.text.trim().isEmpty
              ? null
              : _modelController.text.trim(),
          year: year,
          createdAt: now,
          updatedAt: now,
        );
        await controller.create(created);
      }
      if (context.mounted) {
        context.go('/customers/$customerId');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save vehicle: $error')),
        );
      }
    }
  }
}
