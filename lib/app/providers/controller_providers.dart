import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/approval_controller.dart';
import '../../controllers/customers_controller.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/job_cards_controller.dart';
import '../../controllers/payments_controller.dart';
import '../../controllers/quotation_controller.dart';
import '../../controllers/vehicles_controller.dart';
import '../../services/plan_gate.dart';
import 'repository_providers.dart';

final planGateProvider = Provider<PlanGate>(
  (ref) => PlanGate(ref.watch(garageRepositoryProvider)),
);

final customersControllerProvider = Provider<CustomersController>(
  (ref) => CustomersController(ref.watch(customerRepositoryProvider)),
);

final vehiclesControllerProvider = Provider<VehiclesController>(
  (ref) => VehiclesController(ref.watch(vehicleRepositoryProvider)),
);

final jobCardsControllerProvider = Provider<JobCardsController>(
  (ref) => JobCardsController(
    jobCardRepository: ref.watch(jobCardRepositoryProvider),
    garageRepository: ref.watch(garageRepositoryProvider),
  ),
);

final quotationControllerProvider = Provider<QuotationController>(
  (ref) => QuotationController(
    quotationRepository: ref.watch(quotationRepositoryProvider),
  ),
);

final invoiceControllerProvider = Provider<InvoiceController>(
  (ref) => InvoiceController(
    invoiceRepository: ref.watch(invoiceRepositoryProvider),
    garageRepository: ref.watch(garageRepositoryProvider),
  ),
);

final paymentsControllerProvider = Provider<PaymentsController>(
  (ref) => PaymentsController(
    paymentRepository: ref.watch(paymentRepositoryProvider),
    invoiceRepository: ref.watch(invoiceRepositoryProvider),
    garageRepository: ref.watch(garageRepositoryProvider),
  ),
);

final approvalControllerProvider = Provider<ApprovalController>(
  (ref) => ApprovalController(
    approvalRepository: ref.watch(approvalRepositoryProvider),
    quotationRepository: ref.watch(quotationRepositoryProvider),
    jobCardRepository: ref.watch(jobCardRepositoryProvider),
  ),
);
