import 'package:flutter/material.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _phoneLabel = 'Phone: ';
  static const _notesLabel = 'Notes: ';

  static const _sampleCustomers = [
    _CustomerListItem(
      name: 'Ayesha Motors',
      phone: '+92 300 1111111',
      vehiclePlate: 'ABC-123',
      notes: 'Loyal customer, prefers WhatsApp updates.',
    ),
    _CustomerListItem(
      name: 'Kamran Khan',
      phone: '+92 321 2222222',
      vehiclePlate: 'LEA-9087',
      notes: 'Pending approval for last quote.',
    ),
    _CustomerListItem(
      name: 'Rida Autos',
      phone: '+92 333 3333333',
      vehiclePlate: 'BKZ-4501',
      notes: 'Looking for quick turnaround.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim();
    });
  }

  void _onAddCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer creation coming soon.'),
      ),
    );
  }

  void _onViewCustomer(_CustomerListItem customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${customer.name} coming soon.'),
      ),
    );
  }

  List<_CustomerListItem> get _filteredCustomers {
    if (_query.isEmpty) return _sampleCustomers;
    final normalized = _query.toLowerCase();
    return _sampleCustomers
        .where((customer) => customer.matches(normalized))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddCustomer,
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
                hintText: 'Search by name, phone, or plate',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        title: Text(customer.name),
                        subtitle: Text(
                          '$_phoneLabel${customer.phone}\n$_notesLabel${customer.notes}',
                        ),
                        isThreeLine: true,
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        trailing: Text(
                          customer.vehiclePlate,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        onTap: () => _onViewCustomer(customer),
                      );
                    },
                  ),
          ),
        ],
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

class _CustomerListItem {
  const _CustomerListItem({
    required this.name,
    required this.phone,
    required this.vehiclePlate,
    required this.notes,
  });

  final String name;
  final String phone;
  final String vehiclePlate;
  final String notes;

  bool matches(String normalizedQuery) {
    final lowerName = name.toLowerCase();
    final lowerPhone = phone.toLowerCase();
    final lowerPlate = vehiclePlate.toLowerCase();
    return lowerName.contains(normalizedQuery) ||
        lowerPhone.contains(normalizedQuery) ||
        lowerPlate.contains(normalizedQuery);
  }
}
