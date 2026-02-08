import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/approval_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/garage_repository.dart';
import '../../repositories/invoice_repository.dart';
import '../../repositories/job_card_repository.dart';
// Local implementations (Hive-based)
import '../../repositories/local/local_approval_repository.dart';
import '../../repositories/local/local_auth_repository.dart';
import '../../repositories/local/local_customer_repository.dart';
import '../../repositories/local/local_garage_repository.dart';
import '../../repositories/local/local_invoice_repository.dart';
import '../../repositories/local/local_job_card_repository.dart';
import '../../repositories/local/local_payment_repository.dart';
import '../../repositories/local/local_quotation_repository.dart';
import '../../repositories/local/local_vehicle_repository.dart';
// Mock implementations kept for reference
import '../../repositories/mock/mock_approval_repository.dart';
import '../../repositories/mock/mock_auth_repository.dart';
import '../../repositories/mock/mock_customer_repository.dart';
import '../../repositories/mock/mock_garage_repository.dart';
import '../../repositories/mock/mock_invoice_repository.dart';
import '../../repositories/mock/mock_job_card_repository.dart';
import '../../repositories/mock/mock_payment_repository.dart';
import '../../repositories/mock/mock_quotation_repository.dart';
import '../../repositories/mock/mock_vehicle_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../repositories/quotation_repository.dart';
import '../../repositories/vehicle_repository.dart';

// Local-first implementations using Hive
final garageRepositoryProvider = Provider<GarageRepository>(
  (ref) => LocalGarageRepository(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(
    garageRepository: ref.watch(garageRepositoryProvider),
  ),
);

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => LocalCustomerRepository(),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => LocalVehicleRepository(),
);

final jobCardRepositoryProvider = Provider<JobCardRepository>(
  (ref) => LocalJobCardRepository(),
);

final quotationRepositoryProvider = Provider<QuotationRepository>(
  (ref) => LocalQuotationRepository(),
);

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => LocalInvoiceRepository(),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => LocalPaymentRepository(),
);

final approvalRepositoryProvider = Provider<ApprovalRepository>(
  (ref) => LocalApprovalRepository(),
);

// Mock implementations (kept for reference, not used by default)
/*
final garageRepositoryProvider = Provider<GarageRepository>(
  (ref) => MockGarageRepository(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(
    garageRepository: ref.watch(garageRepositoryProvider),
  ),
);

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => MockCustomerRepository(),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => MockVehicleRepository(),
);

final jobCardRepositoryProvider = Provider<JobCardRepository>(
  (ref) => MockJobCardRepository(),
);

final quotationRepositoryProvider = Provider<QuotationRepository>(
  (ref) => MockQuotationRepository(
    garageRepository: ref.watch(garageRepositoryProvider),
  ),
);

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => MockInvoiceRepository(),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => MockPaymentRepository(
    invoiceRepository: ref.watch(invoiceRepositoryProvider),
  ),
);

final approvalRepositoryProvider = Provider<ApprovalRepository>(
  (ref) => MockApprovalRepository(),
);
*/
