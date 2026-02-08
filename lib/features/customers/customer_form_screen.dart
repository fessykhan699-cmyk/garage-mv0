import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/customer.dart';

final _customerProvider =
    FutureProvider.autoDispose.family<Customer?, String>((ref, id) {
  return ref.watch(customersControllerProvider).fetch(id);
});

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final String? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _load(Customer customer) {
    if (_loaded) return;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _notesController.text = customer.notes ?? '';
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customerId != null;
    final customerAsync = isEditing
        ? ref.watch(_customerProvider(widget.customerId!))
        : const AsyncValue<Customer?>.data(null);

    return AppScaffold(
      title: isEditing ? 'Edit Customer' : 'Add Customer',
      actions: [
        TextButton(
          onPressed: () => _submit(context, isEditing),
          child: const Text('Save'),
        ),
      ],
      body: customerAsync.when(
        data: (customer) {
          if (customer != null) _load(customer);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter customer name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter phone number';
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
                    maxLines: 3,
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
    if (garageId == null || garageId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No garage selected')),
      );
      return;
    }
    final now = DateTime.now();
    final controller = ref.read(customersControllerProvider);
    try {
      if (isEditing) {
        final existing = await controller.fetch(widget.customerId!);
        if (existing == null) {
          throw StateError('Customer not found');
        }
        final updated = Customer(
          id: existing.id,
          garageId: existing.garageId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: existing.createdAt,
          updatedAt: now,
        );
        await controller.update(updated);
      } else {
        final created = Customer(
          id: '',
          garageId: garageId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await controller.create(created);
      }
      if (context.mounted) {
        context.go('/customers');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save customer: $error')),
        );
      }
    }
  }
}
