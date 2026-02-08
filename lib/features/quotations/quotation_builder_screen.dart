import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../core/job_templates.dart';
import '../../models/job_card.dart';
import '../../models/line_item.dart';
import '../../models/quotation.dart';
import '../../services/quote_calculator.dart';

final _quotationProvider =
    FutureProvider.autoDispose.family<Quotation?, String>((ref, id) {
  return ref.watch(quotationControllerProvider).fetch(id);
});

final _jobCardProvider =
    FutureProvider.autoDispose.family<JobCard?, String>((ref, id) {
  return ref.watch(jobCardsControllerProvider).fetch(id);
});

class QuotationBuilderScreen extends ConsumerStatefulWidget {
  const QuotationBuilderScreen({super.key, required this.quotationId});

  final String quotationId;

  @override
  ConsumerState<QuotationBuilderScreen> createState() =>
      _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState
    extends ConsumerState<QuotationBuilderScreen> {
  final _discountController = TextEditingController();
  bool _vatEnabled = false;
  bool _loaded = false;
  String? _templateNote;

  final List<_LineItemDraft> _laborItems = [];
  final List<_LineItemDraft> _partItems = [];

  @override
  void dispose() {
    _discountController.dispose();
    for (final item in _laborItems) {
      item.dispose();
    }
    for (final item in _partItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _load(Quotation quotation) {
    if (_loaded) return;
    _vatEnabled = quotation.vatEnabled;
    _discountController.text =
        quotation.discountAmount == 0 ? '' : quotation.discountAmount.toString();
    _laborItems
      ..clear()
      ..addAll(quotation.laborItems.map(_LineItemDraft.fromItem));
    _partItems
      ..clear()
      ..addAll(quotation.partItems.map(_LineItemDraft.fromItem));
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final quotationAsync = ref.watch(_quotationProvider(widget.quotationId));

    return AppScaffold(
      title: 'Quotation Builder',
      actions: [
        TextButton(
          onPressed: () => _save(context, quotationAsync.value),
          child: const Text('Save'),
        ),
      ],
      body: quotationAsync.when(
        data: (quotation) {
          if (quotation == null) {
            return const Center(child: Text('Quotation not found'));
          }
          _load(quotation);
          final totals = QuoteCalculator.calculateTotals(
            laborItems: _laborItems.map((item) => item.toLineItem()).toList(),
            partItems: _partItems.map((item) => item.toLineItem()).toList(),
            vatEnabled: _vatEnabled,
            discountAmount: _discountAmount,
            vatRate: quotation.vatRate,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: () => _showTemplatePicker(context, quotation),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Apply Template'),
              ),
              if ((_templateNote ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                _TemplateNote(note: _templateNote!),
              ],
              const SizedBox(height: 16),
              _LineItemSection(
                title: 'Labor items',
                items: _laborItems,
                onAdd: () => setState(() => _laborItems.add(_LineItemDraft())),
                onRemove: (index) =>
                    setState(() => _laborItems.removeAt(index).dispose()),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 16),
              _LineItemSection(
                title: 'Parts items',
                items: _partItems,
                onAdd: () => setState(() => _partItems.add(_LineItemDraft())),
                onRemove: (index) =>
                    setState(() => _partItems.removeAt(index).dispose()),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _vatEnabled,
                onChanged: (value) => setState(() => _vatEnabled = value),
                title: const Text('VAT (5%)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _TotalsSummary(totals: totals),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  num get _discountAmount {
    final value = num.tryParse(_discountController.text.trim());
    return value ?? 0;
  }

  Future<void> _save(BuildContext context, Quotation? quotation) async {
    if (quotation == null) return;
    final laborItems = _laborItems.map((item) => item.toLineItem()).toList();
    final partItems = _partItems.map((item) => item.toLineItem()).toList();
    final updated = Quotation(
      id: quotation.id,
      garageId: quotation.garageId,
      jobCardId: quotation.jobCardId,
      customerId: quotation.customerId,
      vehicleId: quotation.vehicleId,
      quoteNumber: quotation.quoteNumber,
      status: quotation.status,
      laborItems: laborItems,
      partItems: partItems,
      vatEnabled: _vatEnabled,
      vatRate: quotation.vatRate,
      subtotal: quotation.subtotal,
      discountAmount: _discountAmount,
      vatAmount: quotation.vatAmount,
      total: quotation.total,
      pdfPath: quotation.pdfPath,
      pdfWatermarked: quotation.pdfWatermarked,
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
        const SnackBar(content: Text('Quotation updated')),
      );
    }
  }

  Future<void> _showTemplatePicker(
    BuildContext context,
    Quotation quotation,
  ) async {
    final template = await showModalBottomSheet<JobTemplate>(
      context: context,
      builder: (context) => ListView(
        children: jobTemplates
            .map(
              (template) => ListTile(
                title: Text(template.name),
                subtitle: Text(template.complaint),
                onTap: () => Navigator.of(context).pop(template),
              ),
            )
            .toList(),
      ),
    );
    if (template == null) return;
    setState(() {
      _laborItems
        ..clear()
        ..addAll(template.laborItems.map(_LineItemDraft.fromItem));
      _partItems
        ..clear()
        ..addAll(template.partItems.map(_LineItemDraft.fromItem));
      _templateNote = template.noteSuggestions;
      _discountController.text = '';
    });
    await _applyTemplateComplaint(quotation, template);
  }

  Future<void> _applyTemplateComplaint(
    Quotation quotation,
    JobTemplate template,
  ) async {
    final jobCard = await ref.read(_jobCardProvider(quotation.jobCardId).future);
    if (jobCard == null) return;
    final updated = JobCard(
      id: jobCard.id,
      garageId: jobCard.garageId,
      customerId: jobCard.customerId,
      vehicleId: jobCard.vehicleId,
      jobCardNumber: jobCard.jobCardNumber,
      complaint: template.complaint,
      notes: jobCard.notes,
      beforePhotoPaths: jobCard.beforePhotoPaths,
      afterPhotoPaths: jobCard.afterPhotoPaths,
      status: jobCard.status,
      createdAt: jobCard.createdAt,
      updatedAt: DateTime.now(),
    );
    await ref.read(jobCardsControllerProvider).update(updated);
  }
}

class _LineItemDraft {
  _LineItemDraft({
    String? name,
    num? qty,
    num? rate,
  })  : nameController = TextEditingController(text: name ?? ''),
        qtyController = TextEditingController(
          text: qty == null ? '' : qty.toString(),
        ),
        rateController = TextEditingController(
          text: rate == null ? '' : rate.toString(),
        );

  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController rateController;

  factory _LineItemDraft.fromItem(LineItem item) {
    return _LineItemDraft(
      name: item.name,
      qty: item.qty,
      rate: item.rate,
    );
  }

  LineItem toLineItem() {
    final qty = num.tryParse(qtyController.text.trim()) ?? 0;
    final rate = num.tryParse(rateController.text.trim()) ?? 0;
    return LineItem(
      name: nameController.text.trim().isEmpty
          ? 'Item'
          : nameController.text.trim(),
      qty: qty,
      rate: rate,
      total: qty * rate,
    );
  }

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    rateController.dispose();
  }
}

class _LineItemSection extends StatelessWidget {
  const _LineItemSection({
    required this.title,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final String title;
  final List<_LineItemDraft> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
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
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: item.nameController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: item.qtyController,
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => onChanged(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: item.rateController,
                            decoration: const InputDecoration(
                              labelText: 'Rate',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => onChanged(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => onRemove(index),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
      ],
    );
  }
}

class _TotalsSummary extends StatelessWidget {
  const _TotalsSummary({required this.totals});

  final QuoteTotals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Subtotal', totals.subtotal),
            if (totals.discountAmount > 0)
              _row('Discount', -totals.discountAmount),
            _row('VAT', totals.vatAmount),
            const Divider(),
            _row('Grand Total', totals.total, bold: true),
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

class _TemplateNote extends StatelessWidget {
  const _TemplateNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(note)),
        ],
      ),
    );
  }
}
