import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';
import '../models/line_item.dart';
import '../models/quotation.dart';

class PdfGeneration {
  PdfGeneration._();

  static const _watermarkLabel =
      'PREVIEW ONLY — Upgrade to Pro to remove watermark';

  /// Build a quotation PDF as raw bytes.
  static Future<Uint8List> buildQuotation(
    Quotation quotation, {
    bool watermarked = false,
  }) {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(watermarked),
        build: (_) => [
          _heading('Quotation', quotation.quoteNumber),
          _keyValue('Garage', quotation.garageId),
          _keyValue('Job Card', quotation.jobCardId),
          _keyValue('Customer', quotation.customerId),
          _keyValue('Vehicle', quotation.vehicleId),
          pw.SizedBox(height: 12),
          if (quotation.laborItems.isNotEmpty)
            _lineItemSection('Labor', quotation.laborItems),
          if (quotation.partItems.isNotEmpty)
            _lineItemSection('Parts', quotation.partItems),
          _totals(
            subtotal: quotation.subtotal,
            vatAmount: quotation.vatAmount,
            total: quotation.total,
          ),
          if (quotation.approvalTokenId != null)
            _keyValue('Approval Token', quotation.approvalTokenId!),
        ],
      ),
    );
    return doc.save();
  }

  /// Build an invoice PDF as raw bytes.
  static Future<Uint8List> buildInvoice(
    Invoice invoice, {
    bool watermarked = false,
  }) {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(watermarked),
        build: (_) => [
          _heading('Invoice', invoice.invoiceNumber),
          _keyValue('Garage', invoice.garageId),
          _keyValue('Quotation', invoice.quotationId),
          _keyValue('Job Card', invoice.jobCardId),
          _keyValue('Customer', invoice.customerId),
          _keyValue('Vehicle', invoice.vehicleId),
          pw.SizedBox(height: 12),
          _totals(
            subtotal: invoice.subtotal,
            vatAmount: invoice.vatAmount,
            total: invoice.total,
          ),
          _keyValue('Amount Paid', _formatMoney(invoice.amountPaid)),
          _keyValue('Balance Due', _formatMoney(invoice.balanceDue)),
        ],
      ),
    );
    return doc.save();
  }

  static pw.PageTheme _pageTheme(bool watermarked) {
    if (!watermarked) return const pw.PageTheme();
    return pw.PageTheme(
      buildBackground: (_) => pw.Center(
        child: pw.Opacity(
          opacity: 0.08,
          child: pw.Transform.rotate(
            angle: -0.3,
            child: pw.Text(
              _watermarkLabel,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _heading(String title, String number) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          number,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _keyValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _lineItemSection(String title, List<LineItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.black),
              children: const [
                pw.Padding(
                  padding: pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Item',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Qty',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Rate',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            ...items.map(
              (item) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(item.name),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(_formatNumber(item.qty)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(_formatMoney(item.rate)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(_formatMoney(item.total)),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _totals({
    required num subtotal,
    required num vatAmount,
    required num total,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _keyValue('Subtotal', _formatMoney(subtotal)),
        _keyValue('VAT', _formatMoney(vatAmount)),
        _keyValue('Total', _formatMoney(total)),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static String _formatMoney(num value) => value.toStringAsFixed(2);

  static String _formatNumber(num value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
}
