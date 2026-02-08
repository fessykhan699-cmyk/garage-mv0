import 'package:go_router/go_router.dart';

import '../../features/approval/approval_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/customer_form_screen.dart';
import '../../features/customers/customers_list_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/invoices/invoice_detail_screen.dart';
import '../../features/invoices/invoices_list_screen.dart';
import '../../features/job_cards/job_card_detail_screen.dart';
import '../../features/job_cards/job_card_form_screen.dart';
import '../../features/job_cards/job_cards_list_screen.dart';
import '../../features/payments/payment_form_screen.dart';
import '../../features/quotations/quotation_builder_screen.dart';
import '../../features/quotations/quotation_detail_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/vehicles/vehicle_form_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const CustomersListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'customersAdd',
            builder: (context, state) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            name: 'customerEdit',
            builder: (context, state) => CustomerFormScreen(
              customerId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: ':id',
            name: 'customerDetail',
            builder: (context, state) => CustomerDetailScreen(
              customerId: state.pathParameters['id'] ?? '',
            ),
            routes: [
              GoRoute(
                path: 'vehicles/add',
                name: 'vehiclesAdd',
                builder: (context, state) => VehicleFormScreen(
                  customerId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'vehicles/:vehicleId/edit',
                name: 'vehiclesEdit',
                builder: (context, state) => VehicleFormScreen(
                  customerId: state.pathParameters['id'],
                  vehicleId: state.pathParameters['vehicleId'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/jobcards',
        name: 'jobcards',
        builder: (context, state) => const JobCardsListScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'jobcardsAdd',
            builder: (context, state) => const JobCardFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'jobcardDetail',
            builder: (context, state) => JobCardDetailScreen(
              jobCardId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/quotations/:id',
        name: 'quotationDetail',
        builder: (context, state) => QuotationDetailScreen(
          quotationId: state.pathParameters['id'] ?? '',
        ),
        routes: [
          GoRoute(
            path: 'builder',
            name: 'quotationBuilder',
            builder: (context, state) => QuotationBuilderScreen(
              quotationId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/approve/:token',
        name: 'approve',
        builder: (context, state) => ApprovalScreen(
          tokenId: state.pathParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/invoices',
        name: 'invoices',
        builder: (context, state) => const InvoicesListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'invoiceDetail',
            builder: (context, state) => InvoiceDetailScreen(
              invoiceId: state.pathParameters['id'] ?? '',
            ),
            routes: [
              GoRoute(
                path: 'payments/add',
                name: 'paymentsAdd',
                builder: (context, state) => PaymentFormScreen(
                  invoiceId: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
