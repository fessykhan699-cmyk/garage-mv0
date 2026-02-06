import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';
import '../models/line_item.dart';
import '../models/quotation.dart';

class PdfGenerator {
  PdfGenerator._();

  /// Generates a quotation PDF, saves it to a temporary file, and returns the path.
  static Future<String> generateQuotationPdf(
    Quotation quotation, {
    bool watermarked = false,
  }) async {
    final bytes = await _buildQuotation(quotation, watermarked: watermarked);
    return _saveTempPdf('quotation-${quotation.id}', bytes);
  }

  /// Generates an invoice PDF, saves it to a temporary file, and returns the path.
  static Future<String> generateInvoicePdf(
    Invoice invoice, {
    bool watermarked = false,
  }) async {
    final bytes = await _buildInvoice(invoice, watermarked: watermarked);
    return _saveTempPdf('invoice-${invoice.id}', bytes);
  }

  static Future<Uint8List> _buildQuotation(
    Quotation quotation, {
    bool watermarked = false,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(watermarked),
        build: (_) => [
          _heading('Quotation', quotation.quoteNumber),
          _keyValue('Customer', quotation.customerId),
          _keyValue('Vehicle', quotation.vehicleId),
          _keyValue('Job Card', quotation.jobCardId),
          pw.SizedBox(height: 12),
          _lineItemSection('Labor', quotation.laborItems),
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

  static Future<Uint8List> _buildInvoice(
    Invoice invoice, {
    bool watermarked = false,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(watermarked),
        build: (_) => [
          _heading('Invoice', invoice.invoiceNumber),
          _keyValue('Quotation', invoice.quotationId),
          _keyValue('Customer', invoice.customerId),
          _keyValue('Vehicle', invoice.vehicleId),
          _keyValue('Job Card', invoice.jobCardId),
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
            angle: -0.25,
            child: pw.Text(
              'PREVIEW ONLY',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 34,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
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
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
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
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static pw.Widget _lineItemSection(String title, List<LineItem> items) {
    if (items.isEmpty) return pw.SizedBox.shrink();
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
          border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey800),
              children: [
                _headerCell('Item'),
                _headerCell('Qty'),
                _headerCell('Rate'),
                _headerCell('Total'),
              ],
            ),
            ...items.map(
              (item) => pw.TableRow(
                children: [
                  _bodyCell(item.name),
                  _bodyCell(_formatNumber(item.qty)),
                  _bodyCell(_formatMoney(item.rate)),
                  _bodyCell(_formatMoney(item.total)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _headerCell(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _bodyCell(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(value),
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

  static Future<String> _saveTempPdf(String prefix, Uint8List bytes) async {
    final dir = await Directory.systemTemp.createTemp('garage-mv0-');
    final file = File('${dir.path}/$prefix.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
