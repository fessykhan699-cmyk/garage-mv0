import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/app_providers.dart';
import '../../app/providers/controller_providers.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../models/invoice.dart';
import '../../models/job_card.dart';
import '../../models/payment.dart';
import '../../models/quotation.dart';

final _jobCardsProvider = StreamProvider.autoDispose<List<JobCard>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null) return Stream.empty();
  return ref.watch(jobCardsControllerProvider).watchByGarage(garageId);
});

final _quotationsProvider = StreamProvider.autoDispose<List<Quotation>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null) return Stream.empty();
  return ref.watch(quotationControllerProvider).watchByGarage(garageId);
});

final _invoicesProvider = StreamProvider.autoDispose<List<Invoice>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null) return Stream.empty();
  return ref.watch(invoiceControllerProvider).watchByGarage(garageId);
});

final _paymentsProvider = StreamProvider.autoDispose<List<Payment>>((ref) {
  final garageId = ref.watch(activeGarageIdProvider);
  if (garageId == null) return Stream.empty();
  return ref.watch(paymentsControllerProvider).watchByGarage(garageId);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;
  static const double _largeScreenBreakpoint = 900;
  static const double _mediumScreenBreakpoint = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobCards = ref.watch(_jobCardsProvider);
    final quotations = ref.watch(_quotationsProvider);
    final invoices = ref.watch(_invoicesProvider);
    final payments = ref.watch(_paymentsProvider);

    final pendingApprovals = quotations.maybeWhen(
      data: (items) => items.where((q) => q.status == QuoteStatus.sent).toList(),
      orElse: () => const <Quotation>[],
    );
    final unpaidInvoices = invoices.maybeWhen(
      data: (items) => items
          .where(
            (invoice) =>
                invoice.status == InvoiceStatus.unpaid ||
                invoice.status == InvoiceStatus.partial,
          )
          .toList(),
      orElse: () => const <Invoice>[],
    );
    final todayPaidTotal = payments.maybeWhen(
      data: (items) => items
          .where((payment) => _isSameDay(payment.paidAt, DateTime.now()))
          .fold<num>(0, (sum, payment) => sum + payment.amount),
      orElse: () => 0,
    );

    final metrics = [
      _DashboardMetric(
        title: 'Paid today',
        value: _formatMoney(todayPaidTotal),
        hint: 'Total payments received today.',
        icon: Icons.payments_outlined,
      ),
      _DashboardMetric(
        title: 'Pending approvals',
        value: '${pendingApprovals.length} quotes',
        hint: 'Awaiting customer approval.',
        icon: Icons.pending_actions_outlined,
      ),
      _DashboardMetric(
        title: 'Unpaid invoices',
        value: '${unpaidInvoices.length} invoices',
        hint: 'Outstanding balance to collect.',
        icon: Icons.receipt_long_outlined,
      ),
      _DashboardMetric(
        title: 'Open job cards',
        value: jobCards.maybeWhen(
          data: (items) => '${items.length} jobs',
          orElse: () => '—',
        ),
        hint: 'Work in progress.',
        icon: Icons.build_circle_outlined,
      ),
    ];

    return AppScaffold(
      title: 'Dashboard',
      body: ListView(
        padding: const EdgeInsets.all(_horizontalPadding),
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: _cardSpacing),
          Wrap(
            spacing: _cardSpacing,
            runSpacing: _cardSpacing,
            children: metrics
                .map(
                  (metric) => _MetricCard(
                    metric: metric,
                    width: _cardWidthFor(context),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 24),
          Text(
            'Quick actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: _cardSpacing),
          Wrap(
            spacing: _cardSpacing,
            runSpacing: _cardSpacing,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/jobcards/add'),
                icon: const Icon(Icons.assignment_add_outlined),
                label: const Text('New Job Card'),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/customers/add'),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('New Customer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _cardWidthFor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final paddedWidth = width - _horizontalPadding * 2;
    if (width >= _largeScreenBreakpoint) {
      return (paddedWidth - _cardSpacing * 2) / 3;
    }
    if (width >= _mediumScreenBreakpoint) {
      return (paddedWidth - _cardSpacing) / 2;
    }
    return paddedWidth;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatMoney(num value) => 'PKR ${value.toStringAsFixed(0)}';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.metric,
    required this.width,
  });

  final _DashboardMetric metric;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(metric.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                metric.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                metric.value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                metric.hint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;
}
