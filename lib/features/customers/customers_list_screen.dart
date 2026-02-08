import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/customer.dart';

final _customerSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final _customersProvider = StreamProvider.autoDispose<List<Customer>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) return Stream.empty();
  final query = ref.watch(_customerSearchProvider);
  return ref.watch(customersControllerProvider).watchByGarage(
        garageId,
        query: query,
      );
});

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      ref.read(_customerSearchProvider.notifier).state =
          _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(_customersProvider);

    return AppScaffold(
      title: 'Customers',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/customers/add'),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search customers',
                hintText: 'Search by name or phone',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: customers.when(
              data: (items) => items.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final customer = items[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(customer.name.isEmpty
                              ? 'Customer ${customer.id}'
                              : customer.name),
                          subtitle: Text(
                            _customerSubtitle(customer),
                          ),
                          trailing: _CustomerActions(customerId: customer.id),
                          onTap: () => context.go('/customers/${customer.id}'),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(error: error),
            ),
          ),
        ],
      ),
    );
  }

  String _customerSubtitle(Customer customer) {
    final buffer = StringBuffer();
    if (customer.phone.isNotEmpty) {
      buffer.write('Phone: ${customer.phone}');
    }
    if ((customer.notes ?? '').isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('Notes: ${customer.notes}');
    }
    return buffer.isEmpty ? 'No notes yet' : buffer.toString();
  }
}

class _CustomerActions extends ConsumerWidget {
  const _CustomerActions({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          context.go('/customers/$customerId/edit');
        }
        if (value == 'delete') {
          _delete(context, ref);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(customersControllerProvider);
    await controller.delete(customerId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer deleted')),
      );
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
            const Icon(Icons.people_outline, size: 56),
            const SizedBox(height: 12),
            Text(
              'No customers yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first customer to start creating job cards and quotes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Failed to load customers: $error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
