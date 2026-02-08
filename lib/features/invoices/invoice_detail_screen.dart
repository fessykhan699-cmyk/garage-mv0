import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/line_item.dart';
import '../../models/payment.dart';
import '../../models/quotation.dart';
import '../../models/vehicle.dart';
import '../../repositories/garage_repository.dart';
import '../../services/pdf_generator.dart';
import '../../services/share_utils.dart';

final _invoiceProvider =
    StreamProvider.autoDispose.family<Invoice?, String>((ref, id) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) {
    return Stream<Invoice?>.empty();
  }
  return ref
      .watch(invoiceControllerProvider)
      .watchByGarage(garageId)
      .map((invoices) => _findInvoice(invoices, id));
});

final _quotationsProvider = StreamProvider.autoDispose<List<Quotation>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) return Stream.empty();
  return ref.watch(quotationControllerProvider).watchByGarage(garageId);
});

final _paymentsProvider =
    StreamProvider.autoDispose.family<List<Payment>, String>((ref, invoiceId) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) return Stream.empty();
  return ref
      .watch(paymentsControllerProvider)
      .watchForInvoice(garageId, invoiceId);
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

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(_invoiceProvider(invoiceId));
    final paymentsAsync = ref.watch(_paymentsProvider(invoiceId));
    final customers = ref.watch(_customersProvider).value ?? const [];
    final vehicles = ref.watch(_vehiclesProvider).value ?? const [];
    final quotations = ref.watch(_quotationsProvider).value ?? const [];
    final garage = ref.watch(activeGarageProvider).value;

    return AppScaffold(
      title: 'Invoice',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_card_outlined),
          onPressed: () => context.go('/invoices/$invoiceId/payments/add'),
        ),
      ],
      body: invoiceAsync.when(
        data: (invoice) {
          if (invoice == null) {
            return const Center(child: Text('Invoice not found'));
          }
          final customer = _findCustomer(customers, invoice.customerId);
          final vehicle = _findVehicle(vehicles, invoice.vehicleId);
          final quotation = _findQuotation(quotations, invoice.quotationId);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(invoice: invoice),
              const SizedBox(height: 16),
              _TotalsCard(invoice: invoice),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: garage == null || customer == null || vehicle == null
                        ? null
                        : () => _generatePdf(
                              context,
                              ref,
                              invoice,
                              garage,
                              customer,
                              vehicle,
                              quotation,
                            ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Generate PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: invoice.pdfPath == null || customer == null
                        ? null
                        : () => _shareInvoice(
                              context,
                              ref,
                              invoice,
                              customer,
                              vehicle,
                            ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Payments', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              paymentsAsync.when(
                data: (payments) => payments.isEmpty
                    ? const Text('No payments recorded yet.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return ListTile(
                            title: Text(
                              payment.amount.toStringAsFixed(2),
                            ),
                            subtitle: Text(
                              '${payment.method.name} • ${_formatDate(payment.paidAt)}',
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Error: $error'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    WidgetRef ref,
    Invoice invoice,
    Garage garage,
    Customer customer,
    Vehicle vehicle,
    Quotation? quotation,
  ) async {
    final allowed = await _ensurePro(context, ref, invoice.garageId);
    if (!allowed) return;
    final items = quotation == null
        ? const <LineItem>[]
        : [
            ...quotation.laborItems,
            ...quotation.partItems,
          ];
    final pdfPath = await PdfGenerator.generateInvoicePdf(
      garage: garage,
      customer: customer,
      vehicle: vehicle,
      invoice: invoice,
      lineItems: items,
    );
    await ref.read(invoiceControllerProvider).attachPdf(invoice.id, pdfPath);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice PDF generated.')),
      );
    }
  }

  Future<void> _shareInvoice(
    BuildContext context,
    WidgetRef ref,
    Invoice invoice,
    Customer customer,
    Vehicle? vehicle,
  ) async {
    if (invoice.pdfPath == null) return;
    final allowed = await _ensurePro(context, ref, invoice.garageId);
    if (!allowed) return;
    final message = ShareUtils.invoiceMessage(
      customerName: customer.name.isEmpty ? 'Customer' : customer.name,
      vehiclePlate: vehicle?.plateNumber ?? 'Vehicle',
      total: invoice.balanceDue,
    );
    await ShareUtils.sharePdfFile(filePath: invoice.pdfPath!, message: message);
  }

  Future<bool> _ensurePro(
    BuildContext context,
    WidgetRef ref,
    String garageId,
  ) async {
    final planGate = ref.read(planGateProvider);
    final allowed = await planGate.canUseProForGarage(garageId);
    if (allowed) return true;
    final enable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text(
          'This feature requires a Pro plan. Enable Pro for testing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable Pro'),
          ),
        ],
      ),
    );
    if (enable == true) {
      await planGate.manualProToggle(garageId, enable: true);
      return true;
    }
    return false;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.invoiceNumber,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Status: ${invoice.status.name}'),
            Text('Balance: ${invoice.balanceDue.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Subtotal', invoice.subtotal),
            if (invoice.discountAmount > 0)
              _row('Discount', -invoice.discountAmount),
            _row('VAT', invoice.vatAmount),
            const Divider(),
            _row('Grand Total', invoice.total, bold: true),
            const SizedBox(height: 8),
            _row('Paid', invoice.amountPaid),
            _row('Balance', invoice.balanceDue, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, num value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}

Invoice? _findInvoice(List<Invoice> invoices, String id) {
  for (final invoice in invoices) {
    if (invoice.id == id) return invoice;
  }
  return null;
}

Customer? _findCustomer(List<Customer> customers, String id) {
  for (final customer in customers) {
    if (customer.id == id) return customer;
  }
  return null;
}

Vehicle? _findVehicle(List<Vehicle> vehicles, String id) {
  for (final vehicle in vehicles) {
    if (vehicle.id == id) return vehicle;
  }
  return null;
}

Quotation? _findQuotation(List<Quotation> quotations, String id) {
  for (final quote in quotations) {
    if (quote.id == id) return quote;
  }
  return null;
}
