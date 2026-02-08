import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../core/app_constants.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/job_card.dart';
import '../../models/line_item.dart';
import '../../models/quotation.dart';
import '../../models/vehicle.dart';
import '../../repositories/garage_repository.dart';
import '../../services/pdf_generator.dart';
import '../../services/share_utils.dart';

final _quotationProvider =
    StreamProvider.autoDispose.family<Quotation?, String>((ref, id) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) {
    return Stream<Quotation?>.empty();
  }
  return ref
      .watch(quotationControllerProvider)
      .watchByGarage(garageId)
      .map((quotes) => _findQuotation(quotes, id));
});

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

final _invoicesProvider = StreamProvider.autoDispose<List<Invoice>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null || garageId.isEmpty) return Stream.empty();
  return ref.watch(invoiceControllerProvider).watchByGarage(garageId);
});

class QuotationDetailScreen extends ConsumerWidget {
  const QuotationDetailScreen({super.key, required this.quotationId});

  final String quotationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotationAsync = ref.watch(_quotationProvider(quotationId));
    final jobCards = ref.watch(_jobCardsProvider).value ?? const [];
    final customers = ref.watch(_customersProvider).value ?? const [];
    final vehicles = ref.watch(_vehiclesProvider).value ?? const [];
    final invoices = ref.watch(_invoicesProvider).value ?? const [];
    final garage = ref.watch(activeGarageProvider).value;

    return AppScaffold(
      title: 'Quotation',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.go('/quotations/$quotationId/builder'),
        ),
      ],
      body: quotationAsync.when(
        data: (quotation) {
          if (quotation == null) {
            return const Center(child: Text('Quotation not found'));
          }
          final jobCard = _findJobCard(jobCards, quotation.jobCardId);
          final customer = _findCustomer(customers, quotation.customerId);
          final vehicle = _findVehicle(vehicles, quotation.vehicleId);
          final invoice = _findInvoice(invoices, quotation.id);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(quotation: quotation),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Customer',
                lines: [
                  customer?.name ?? 'Customer ${quotation.customerId}',
                  if ((customer?.phone ?? '').isNotEmpty)
                    'Phone: ${customer?.phone}',
                ],
              ),
              const SizedBox(height: 8),
              _InfoCard(
                title: 'Vehicle',
                lines: [
                  vehicle?.plateNumber ?? 'Vehicle ${quotation.vehicleId}',
                  if ((vehicle?.make ?? '').isNotEmpty)
                    'Make: ${vehicle?.make}',
                  if ((vehicle?.model ?? '').isNotEmpty)
                    'Model: ${vehicle?.model}',
                ],
              ),
              if (jobCard != null) ...[
                const SizedBox(height: 8),
                _InfoCard(
                  title: 'Job Card',
                  lines: [
                    jobCard.jobCardNumber,
                    jobCard.complaint,
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _LineItemsSection(title: 'Labor', items: quotation.laborItems),
              const SizedBox(height: 12),
              _LineItemsSection(title: 'Parts', items: quotation.partItems),
              const SizedBox(height: 16),
              _TotalsCard(quotation: quotation),
              const SizedBox(height: 16),
              if (quotation.approvalTokenId != null)
                _ApprovalLink(
                  tokenId: quotation.approvalTokenId!,
                  onCopy: () => _copyLink(context, quotation.approvalTokenId!),
                  onOpen: () => context.go('/approve/${quotation.approvalTokenId}'),
                ),
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
                              quotation,
                              garage,
                              customer,
                              vehicle,
                            ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Generate PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: quotation.pdfPath == null || customer == null
                        ? null
                        : () => _shareQuote(
                              context,
                              ref,
                              quotation,
                              customer,
                              vehicle,
                            ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _createApproval(
                      context,
                      ref,
                      quotation,
                    ),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Create approval link'),
                  ),
                  if (quotation.status == QuoteStatus.approved && invoice == null)
                    FilledButton.icon(
                      onPressed: () => _convertToInvoice(
                        context,
                        ref,
                        quotation,
                      ),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('Convert to invoice'),
                    ),
                  if (invoice != null)
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/invoices/${invoice.id}'),
                      icon: const Icon(Icons.receipt_outlined),
                      label: const Text('View invoice'),
                    ),
                ],
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
    Quotation quotation,
    Garage garage,
    Customer customer,
    Vehicle vehicle,
  ) async {
    final garageId = quotation.garageId;
    final allowed = await _ensurePro(context, ref, garageId);
    if (!allowed) return;
    final pdfPath = await PdfGenerator.generateQuotationPdf(
      garage: garage,
      customer: customer,
      vehicle: vehicle,
      quotation: quotation,
    );
    final updated = Quotation(
      id: quotation.id,
      garageId: quotation.garageId,
      jobCardId: quotation.jobCardId,
      customerId: quotation.customerId,
      vehicleId: quotation.vehicleId,
      quoteNumber: quotation.quoteNumber,
      status: quotation.status,
      laborItems: quotation.laborItems,
      partItems: quotation.partItems,
      vatEnabled: quotation.vatEnabled,
      vatRate: quotation.vatRate,
      subtotal: quotation.subtotal,
      discountAmount: quotation.discountAmount,
      vatAmount: quotation.vatAmount,
      total: quotation.total,
      pdfPath: pdfPath,
      pdfWatermarked: false,
      approvalTokenId: quotation.approvalTokenId,
      approvedAt: quotation.approvedAt,
      rejectedAt: quotation.rejectedAt,
      customerComment: quotation.customerComment,
      createdAt: quotation.createdAt,
      updatedAt: DateTime.now(),
    );
    await ref.read(quotationControllerProvider).update(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation PDF generated.')),
      );
    }
  }

  Future<void> _shareQuote(
    BuildContext context,
    WidgetRef ref,
    Quotation quotation,
    Customer customer,
    Vehicle? vehicle,
  ) async {
    if (quotation.pdfPath == null) return;
    final allowed = await _ensurePro(context, ref, quotation.garageId);
    if (!allowed) return;
    String? tokenId = quotation.approvalTokenId;
    if (tokenId == null) {
      final token = await ref.read(approvalControllerProvider).createToken(
            garageId: quotation.garageId,
            quotationId: quotation.id,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          );
      tokenId = token.id;
    }
    final approvalLink = buildApprovalLink(tokenId);
    final message = ShareUtils.quotationMessage(
      customerName: customer.name.isEmpty ? 'Customer' : customer.name,
      vehiclePlate: vehicle?.plateNumber ?? 'Vehicle',
      total: quotation.total,
      approvalLink: approvalLink,
    );
    await ShareUtils.sharePdfFile(
      filePath: quotation.pdfPath!,
      message: message,
    );
  }

  Future<void> _createApproval(
    BuildContext context,
    WidgetRef ref,
    Quotation quotation,
  ) async {
    final garageId = quotation.garageId;
    final allowed = await _ensurePro(context, ref, garageId);
    if (!allowed) return;
    try {
      final token = await ref.read(approvalControllerProvider).createToken(
            garageId: garageId,
            quotationId: quotation.id,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval link: ${token.id}')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create link: $error')),
        );
      }
    }
  }

  Future<void> _convertToInvoice(
    BuildContext context,
    WidgetRef ref,
    Quotation quotation,
  ) async {
    try {
      final invoice = await ref
          .read(invoiceControllerProvider)
          .createFromQuotation(quotation);
      if (context.mounted) {
        context.go('/invoices/${invoice.id}');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create invoice: $error')),
        );
      }
    }
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

  void _copyLink(BuildContext context, String tokenId) {
    final link = buildApprovalLink(tokenId);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Approval link copied.')),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.quotation});

  final Quotation quotation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quotation.quoteNumber,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Status: ${quotation.status.name}'),
            if (quotation.approvalTokenId != null)
              Text('Approval token: ${quotation.approvalTokenId}'),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            ...lines.map((line) => Text(line)),
          ],
        ),
      ),
    );
  }
}

class _LineItemsSection extends StatelessWidget {
  const _LineItemsSection({required this.title, required this.items});

  final String title;
  final List<LineItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('$title: No items added.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.name),
              subtitle: Text('Qty ${item.qty} • Rate ${item.rate}'),
              trailing: Text(item.total.toStringAsFixed(2)),
            );
          },
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.quotation});

  final Quotation quotation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _totalRow('Subtotal', quotation.subtotal),
            if (quotation.discountAmount > 0)
              _totalRow('Discount', -quotation.discountAmount),
            _totalRow('VAT', quotation.vatAmount),
            const Divider(),
            _totalRow('Grand Total', quotation.total, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, num value, {bool bold = false}) {
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

class _ApprovalLink extends StatelessWidget {
  const _ApprovalLink({
    required this.tokenId,
    required this.onCopy,
    required this.onOpen,
  });

  final String tokenId;
  final VoidCallback onCopy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final link = buildApprovalLink(tokenId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approval link', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            SelectableText(link),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: const Text('Open'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Quotation? _findQuotation(List<Quotation> quotes, String id) {
  for (final quote in quotes) {
    if (quote.id == id) return quote;
  }
  return null;
}

JobCard? _findJobCard(List<JobCard> cards, String id) {
  for (final card in cards) {
    if (card.id == id) return card;
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

Invoice? _findInvoice(List<Invoice> invoices, String quotationId) {
  for (final invoice in invoices) {
    if (invoice.quotationId == quotationId) return invoice;
  }
  return null;
}
