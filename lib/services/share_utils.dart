import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

class ShareUtils {
  ShareUtils._();

  /// WhatsApp-friendly quotation message template.
  static String quotationMessage({
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

  /// WhatsApp-friendly invoice message template.
  static String invoiceMessage({
    required String customerName,
    required String vehiclePlate,
    required num total,
  }) {
    final totalText = _formatTotal(total);
    return 'Hi $customerName, your invoice for $vehiclePlate is ready.\n'
        'Amount due: $totalText.\n'
        'PDF attached. Thank you.';
  }

  /// Share PDF bytes with an optional message (e.g., WhatsApp).
  static Future<void> sharePdfBytes({
    required Uint8List bytes,
    required String filename,
    String? message,
  }) {
    final file = XFile.fromData(
      bytes,
      mimeType: 'application/pdf',
      name: filename,
    );
    return Share.shareXFiles([file], text: message);
  }

  /// Share an existing PDF file path with an optional message.
  static Future<void> sharePdfFile({
    required String filePath,
    String? message,
  }) {
    final file = XFile(
      filePath,
      mimeType: 'application/pdf',
      name: filePath.split('/').last,
    );
    return Share.shareXFiles([file], text: message);
  }

  static String _formatTotal(num total) =>
      total % 1 == 0 ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
}
