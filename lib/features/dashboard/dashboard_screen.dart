import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _metrics = [
    _DashboardMetric(
      title: 'Paid today',
      value: 'PKR 0',
      hint: 'Record payments to see today’s total.',
      icon: Icons.payments_outlined,
    ),
    _DashboardMetric(
      title: 'Pending approvals',
      value: '0 quotes',
      hint: 'Send approval links to customers.',
      icon: Icons.pending_actions_outlined,
    ),
    _DashboardMetric(
      title: 'Unpaid invoices',
      value: '0 invoices',
      hint: 'Track outstanding amounts here.',
      icon: Icons.receipt_long_outlined,
    ),
    _DashboardMetric(
      title: 'Open job cards',
      value: '0 jobs',
      hint: 'Create job cards to start work.',
      icon: Icons.build_circle_outlined,
    ),
  ];

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;
  static const double _largeScreenBreakpoint = 900;
  static const double _mediumScreenBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
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
            children: _metrics
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
                onPressed: () => _showComingSoon(context),
                icon: const Icon(Icons.assignment_add_outlined),
                label: const Text('New Job Card'),
              ),
              FilledButton.icon(
                onPressed: () => _showComingSoon(context),
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon. This action will be wired up next.'),
      ),
    );
  }
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
