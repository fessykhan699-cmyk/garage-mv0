import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/invoice.dart';

final _invoicesProvider = StreamProvider.autoDispose<List<Invoice>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) return Stream.empty();
  return ref.watch(invoiceControllerProvider).watchByGarage(garageId);
});

class InvoicesListScreen extends ConsumerWidget {
  const InvoicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(_invoicesProvider);

    return AppScaffold(
      title: 'Invoices',
      body: invoices.when(
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final invoice = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(invoice.invoiceNumber),
                      subtitle: Text(
                        'Total: ${invoice.total.toStringAsFixed(2)}\n'
                        'Balance: ${invoice.balanceDue.toStringAsFixed(2)}',
                      ),
                      isThreeLine: true,
                      trailing: Text(invoice.status.name),
                      onTap: () => context.go('/invoices/${invoice.id}'),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
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
            const Icon(Icons.receipt_long_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'No invoices yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Convert approved quotations to invoices.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
