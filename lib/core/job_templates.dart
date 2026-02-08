import '../models/line_item.dart';

class JobTemplate {
  const JobTemplate({
    required this.name,
    required this.complaint,
    required this.laborItems,
    required this.partItems,
    this.noteSuggestions,
  });

  final String name;
  final String complaint;
  final List<LineItem> laborItems;
  final List<LineItem> partItems;
  final String? noteSuggestions;
}

const List<JobTemplate> jobTemplates = [
  JobTemplate(
    name: 'Oil Change',
    complaint: 'Engine oil change service',
    laborItems: [
      LineItem(name: 'Labor Charge', qty: 1, rate: 800, total: 800),
    ],
    partItems: [
      LineItem(name: 'Engine Oil', qty: 4, rate: 450, total: 1800),
      LineItem(name: 'Oil Filter', qty: 1, rate: 350, total: 350),
    ],
    noteSuggestions: 'Replace oil filter and check for leaks.',
  ),
  JobTemplate(
    name: 'Battery Replace',
    complaint: 'Battery replacement required',
    laborItems: [
      LineItem(name: 'Labor Charge', qty: 1, rate: 600, total: 600),
    ],
    partItems: [
      LineItem(name: 'Car Battery', qty: 1, rate: 6500, total: 6500),
    ],
    noteSuggestions: 'Check alternator output after install.',
  ),
  JobTemplate(
    name: 'AC Gas Refill',
    complaint: 'AC gas refill needed',
    laborItems: [
      LineItem(name: 'AC Gas Service', qty: 1, rate: 1500, total: 1500),
    ],
    partItems: [
      LineItem(name: 'AC Gas', qty: 1, rate: 2000, total: 2000),
    ],
    noteSuggestions: 'Inspect for AC leaks before refilling.',
  ),
  JobTemplate(
    name: 'Recovery',
    complaint: 'Vehicle recovery service',
    laborItems: [
      LineItem(name: 'Recovery Service', qty: 1, rate: 3000, total: 3000),
    ],
    partItems: const [],
    noteSuggestions: 'Include pickup and drop-off details.',
  ),
  JobTemplate(
    name: 'Brake Pads',
    complaint: 'Brake pad replacement',
    laborItems: [
      LineItem(name: 'Labor Charge', qty: 1, rate: 1200, total: 1200),
    ],
    partItems: [
      LineItem(name: 'Brake Pad Set', qty: 1, rate: 4200, total: 4200),
    ],
    noteSuggestions: 'Resurface discs if needed.',
  ),
  JobTemplate(
    name: 'Wheel Alignment',
    complaint: 'Wheel alignment and balancing',
    laborItems: [
      LineItem(name: 'Alignment Service', qty: 1, rate: 1800, total: 1800),
    ],
    partItems: const [],
    noteSuggestions: 'Check tyre pressure after alignment.',
  ),
  JobTemplate(
    name: 'Minor Service',
    complaint: 'Minor service package',
    laborItems: [
      LineItem(name: 'Service Labor', qty: 1, rate: 2000, total: 2000),
    ],
    partItems: [
      LineItem(name: 'Air Filter', qty: 1, rate: 650, total: 650),
      LineItem(name: 'Cabin Filter', qty: 1, rate: 550, total: 550),
    ],
    noteSuggestions: 'Inspect fluids and top up as needed.',
  ),
];
