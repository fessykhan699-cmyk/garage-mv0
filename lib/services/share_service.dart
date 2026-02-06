import 'dart:io';

import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._();

  static String quotationTemplate({
    required String customerName,
    required String vehiclePlate,
    required num total,
    required String approvalLink,
  }) {
    final totalText = _formatTotal(total);
    return 'Hi $customerName, here is your quotation for $vehiclePlate.\n'
        'Total: $totalText.\n'
        'Please approve or reject here: $approvalLink.\n'
        'PDF attached.';
  }

  static String invoiceTemplate({
    required String customerName,
    required String vehiclePlate,
    required num total,
  }) {
    final totalText = _formatTotal(total);
    return 'Hi $customerName, your invoice for $vehiclePlate is ready.\n'
        'Amount due: $totalText.\n'
        'PDF attached. Thank you.';
  }

  static Future<void> sharePdf({
    required String filePath,
    String? message,
  }) async {
    final filename = _basename(filePath);
    final file = XFile(
      filePath,
      mimeType: 'application/pdf',
      name: filename,
    );
    await Share.shareXFiles([file], text: message);
  }

  static String _basename(String path) {
    final segments = File(path).uri.pathSegments.where((s) => s.isNotEmpty);
    return segments.isNotEmpty ? segments.last : path.split(Platform.pathSeparator).last;
  }

  static String _formatTotal(num total) =>
      total % 1 == 0 ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
}
