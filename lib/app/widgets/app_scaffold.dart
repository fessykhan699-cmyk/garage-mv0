import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: _AppDrawer(onLogout: () async {
        await ref.read(authControllerProvider.notifier).signOut();
        if (context.mounted) {
          context.go('/login');
        }
      }),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Text(
              'Garage MVP',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _DrawerItem(
            title: 'Dashboard',
            icon: Icons.dashboard_outlined,
            onTap: () => _go(context, '/dashboard'),
          ),
          _DrawerItem(
            title: 'Customers',
            icon: Icons.people_outline,
            onTap: () => _go(context, '/customers'),
          ),
          _DrawerItem(
            title: 'Job Cards',
            icon: Icons.build_outlined,
            onTap: () => _go(context, '/jobcards'),
          ),
          _DrawerItem(
            title: 'Invoices',
            icon: Icons.receipt_long_outlined,
            onTap: () => _go(context, '/invoices'),
          ),
          _DrawerItem(
            title: 'Settings',
            icon: Icons.settings_outlined,
            onTap: () => _go(context, '/settings'),
          ),
          const Divider(),
          _DrawerItem(
            title: 'Logout',
            icon: Icons.logout,
            onTap: () {
              Navigator.of(context).pop();
              onLogout();
            },
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
