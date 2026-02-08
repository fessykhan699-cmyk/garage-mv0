import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';

/// Provider for the app router with authentication redirect
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final path = state.uri.path;
      
      // Public routes that don't require authentication
      if (path.startsWith('/approve/')) {
        return null;
      }
      
      // If not authenticated and not on login, redirect to login
      if (!isAuthenticated && path != '/login') {
        return '/login';
      }
      
      // If authenticated and on login, redirect to dashboard
      if (isAuthenticated && path == '/login') {
        return '/dashboard';
      }
      
      return null;
    },
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
        ],
      ),
      GoRoute(
        path: '/vehicles',
        name: 'vehicles',
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'] ?? '';
          return _RoutePlaceholder('Vehicles for $customerId');
        },
        routes: [
          GoRoute(
            path: 'add',
            name: 'vehiclesAdd',
            builder: (context, state) {
              final customerId = state.uri.queryParameters['customerId'] ?? '';
              return _RoutePlaceholder('Add Vehicle for $customerId');
            },
          ),
        ],
      ),
      GoRoute(
        path: '/jobCards',
        name: 'jobCards',
        builder: (context, state) => const _RoutePlaceholder('Job Cards'),
        routes: [
          GoRoute(
            path: 'create',
            name: 'jobCardsCreate',
            builder: (context, state) =>
                const _RoutePlaceholder('Create Job Card'),
          ),
          GoRoute(
            path: ':id',
            name: 'jobCardDetail',
            builder: (context, state) => _RoutePlaceholder(
              'Job Card ${state.pathParameters['id'] ?? ''}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/quotation/create',
        name: 'quotationCreate',
        builder: (context, state) {
          final jobCardId = state.uri.queryParameters['jobCardId'] ?? '';
          return _RoutePlaceholder('Create Quotation for $jobCardId');
        },
      ),
      GoRoute(
        path: '/quotation/:id',
        name: 'quotationDetail',
        builder: (context, state) => _RoutePlaceholder(
          'Quotation ${state.pathParameters['id'] ?? ''}',
        ),
      ),
      GoRoute(
        path: '/invoice/create',
        name: 'invoiceCreate',
        builder: (context, state) {
          final quotationId = state.uri.queryParameters['quotationId'] ?? '';
          return _RoutePlaceholder('Create Invoice for $quotationId');
        },
      ),
      GoRoute(
        path: '/invoice/:id',
        name: 'invoiceDetail',
        builder: (context, state) => _RoutePlaceholder(
          'Invoice ${state.pathParameters['id'] ?? ''}',
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const _RoutePlaceholder('Settings'),
      ),
      // Public approval route (no auth required)
      GoRoute(
        path: '/approve/:token',
        name: 'approve',
        builder: (context, state) => _RoutePlaceholder(
          'Approve ${state.pathParameters['token'] ?? ''}',
        ),
      ),
    ],
  );
});

class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
