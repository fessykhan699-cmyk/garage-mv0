import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const _RoutePlaceholder('Login'),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const _RoutePlaceholder('Dashboard'),
      ),
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const _RoutePlaceholder('Customers'),
        routes: [
          GoRoute(
            path: 'add',
            name: 'customersAdd',
            builder: (context, state) =>
                const _RoutePlaceholder('Add Customer'),
          ),
          GoRoute(
            path: ':id',
            name: 'customerDetail',
            builder: (context, state) => _RoutePlaceholder(
              'Customer ${state.pathParameters['id'] ?? ''}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/vehicles/add',
        name: 'vehiclesAdd',
        builder: (context, state) => _RoutePlaceholder(
          'Add Vehicle for ${state.queryParameters['customerId'] ?? ''}',
        ),
      ),
      GoRoute(
        path: '/jobcards',
        name: 'jobcards',
        builder: (context, state) => const _RoutePlaceholder('Job Cards'),
        routes: [
          GoRoute(
            path: 'add',
            name: 'jobcardsAdd',
            builder: (context, state) =>
                const _RoutePlaceholder('Add Job Card'),
          ),
          GoRoute(
            path: ':id',
            name: 'jobcardDetail',
            builder: (context, state) => _RoutePlaceholder(
              'Job Card ${state.pathParameters['id'] ?? ''}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/quotations/:id',
        name: 'quotationDetail',
        builder: (context, state) => _RoutePlaceholder(
          'Quotation ${state.pathParameters['id'] ?? ''}',
        ),
        routes: [
          GoRoute(
            path: 'builder',
            name: 'quotationBuilder',
            builder: (context, state) => _RoutePlaceholder(
              'Quotation Builder ${state.pathParameters['id'] ?? ''}',
            ),
          ),
          GoRoute(
            path: 'preview',
            name: 'quotationPreview',
            builder: (context, state) => _RoutePlaceholder(
              'Quotation Preview ${state.pathParameters['id'] ?? ''}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/approve/:token',
        name: 'approve',
        builder: (context, state) => _RoutePlaceholder(
          'Approve ${state.pathParameters['token'] ?? ''}',
        ),
      ),
      GoRoute(
        path: '/invoices/:id',
        name: 'invoiceDetail',
        builder: (context, state) => _RoutePlaceholder(
          'Invoice ${state.pathParameters['id'] ?? ''}',
        ),
      ),
      GoRoute(
        path: '/payments/add',
        name: 'paymentsAdd',
        builder: (context, state) => _RoutePlaceholder(
          'Add Payment for ${state.queryParameters['invoiceId'] ?? ''}',
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const _RoutePlaceholder('Settings'),
      ),
    ],
  );
}

class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
