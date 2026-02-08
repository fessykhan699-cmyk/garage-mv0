import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../controllers/garage_controller.dart';
import '../../repositories/garage_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _trnController = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _trnController.dispose();
    super.dispose();
  }

  void _load(Garage garage) {
    if (_loaded) return;
    _nameController.text = garage.name ?? '';
    _phoneController.text = garage.phone ?? '';
    _emailController.text = garage.email ?? '';
    _addressController.text = garage.address ?? '';
    _trnController.text = garage.trn ?? '';
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final garageId = ref.watch(activeGarageIdProvider);
    if (garageId == null) {
      return const Scaffold(body: Center(child: Text('No garage selected.')));
    }
    final garageAsync = ref.watch(garageControllerProvider(garageId));

    return AppScaffold(
      title: 'Settings',
      actions: [
        TextButton(
          onPressed: () => _save(context, garageId),
          child: const Text('Save'),
        ),
      ],
      body: garageAsync.when(
        data: (garage) {
          final currentGarage = garage ?? Garage(id: garageId);
          _load(currentGarage);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Garage name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter garage name';
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _trnController,
                    decoration: const InputDecoration(
                      labelText: 'TRN (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: currentGarage.plan.toLowerCase() == 'pro',
                    onChanged: (value) => _togglePlan(value, garageId),
                    title: const Text('Pro plan (manual toggle)'),
                    subtitle: const Text(
                      'Enable for testing PDF, approvals, and payments.',
                    ),
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

  Future<void> _save(BuildContext context, String garageId) async {
    if (_formKey.currentState?.validate() != true) return;
    final controller = ref.read(garageControllerProvider(garageId).notifier);
    final existing = ref.read(garageControllerProvider(garageId)).value;
    final updated = Garage(
      id: garageId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      trn: _trnController.text.trim().isEmpty
          ? null
          : _trnController.text.trim(),
      plan: existing?.plan ?? 'free',
      usage: existing?.usage,
      createdAt: existing?.createdAt,
    );
    await controller.updateGarage(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _togglePlan(bool isPro, String garageId) async {
    await ref
        .read(garageControllerProvider(garageId).notifier)
        .updatePlan(isPro ? 'pro' : 'free');
  }
}
