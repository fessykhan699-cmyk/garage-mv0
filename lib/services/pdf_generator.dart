import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/line_item.dart';
import '../models/quotation.dart';
import '../models/vehicle.dart';
import '../repositories/garage_repository.dart';

class PdfGenerator {
  PdfGenerator._();

  static Future<String> generateQuotationPdf({
    required Garage garage,
    required Customer customer,
    required Vehicle vehicle,
    required Quotation quotation,
    bool watermarked = false,
  }) async {
    final bytes = await _buildQuotation(
      garage: garage,
      customer: customer,
      vehicle: vehicle,
      quotation: quotation,
      watermarked: watermarked,
    );
    return _saveTempPdf('quotation-${quotation.id}', bytes);
  }

  static Future<String> generateInvoicePdf({
    required Garage garage,
    required Customer customer,
    required Vehicle vehicle,
    required Invoice invoice,
    List<LineItem> lineItems = const [],
    bool watermarked = false,
  }) async {
    final bytes = await _buildInvoice(
      garage: garage,
      customer: customer,
      vehicle: vehicle,
      invoice: invoice,
      lineItems: lineItems,
      watermarked: watermarked,
    );
    return _saveTempPdf('invoice-${invoice.id}', bytes);
  }

  static Future<Uint8List> _buildQuotation({
    required Garage garage,
    required Customer customer,
    required Vehicle vehicle,
    required Quotation quotation,
    required bool watermarked,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(watermarked),
        build: (_) => [
          _header(
            garage: garage,
            title: 'Quotation',
            metaLines: [
              _metaLine('Quote #', quotation.quoteNumber),
              _metaLine('Job Card #', quotation.jobCardId),
              _metaLine('Date', _formatDate(quotation.createdAt)),
            ],
          ),
          pw.SizedBox(height: 16),
          _infoBlocks(customer: customer, vehicle: vehicle),
          pw.SizedBox(height: 16),
          _lineItemsTable(
            items: _mergeLineItems(
              laborItems: quotation.laborItems,
              partItems: quotation.partItems,
            ),
          ),
          pw.SizedBox(height: 12),
          _totalsSection(
            subtotal: quotation.subtotal,
            discountAmount: quotation.discountAmount,
            vatAmount: quotation.vatAmount,
            total: quotation.total,
          ),
          pw.SizedBox(height: 20),
          _footer(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> _buildInvoice({
    required Garage garage,
    required Customer customer,
    required Vehicle vehicle,
    required Invoice invoice,
    required List<LineItem> lineItems,
    required bool watermarked,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(watermarked),
        build: (_) => [
          _header(
            garage: garage,
            title: 'Tax Invoice',
            metaLines: [
              _metaLine('Invoice #', invoice.invoiceNumber),
              _metaLine('Job Card #', invoice.jobCardId),
              _metaLine('Date', _formatDate(invoice.createdAt)),
            ],
          ),
          pw.SizedBox(height: 16),
          _infoBlocks(customer: customer, vehicle: vehicle),
          pw.SizedBox(height: 16),
          _lineItemsTable(items: lineItems),
          pw.SizedBox(height: 12),
          _totalsSection(
            subtotal: invoice.subtotal,
            discountAmount: invoice.discountAmount,
            vatAmount: invoice.vatAmount,
            total: invoice.total,
          ),
          pw.SizedBox(height: 12),
          _paymentSummary(
            paid: invoice.amountPaid,
            balance: invoice.balanceDue,
          ),
          pw.SizedBox(height: 20),
          _footer(),
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

  static pw.Widget _header({
    required Garage garage,
    required String title,
    required List<pw.Widget> metaLines,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                garage.name ?? 'Garage',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (garage.phone != null)
                pw.Text('Phone: ${garage.phone}'),
              if (garage.email != null)
                pw.Text('Email: ${garage.email}'),
              if (garage.address != null)
                pw.Text('Address: ${garage.address}'),
              if (garage.trn != null) pw.Text('TRN: ${garage.trn}'),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 8),
            ...metaLines,
          ],
        ),
      ],
    );
  }

  static pw.Widget _metaLine(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
        ),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _infoBlocks({
    required Customer customer,
    required Vehicle vehicle,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _infoBlock(
            title: 'Customer',
            lines: [
              customer.name,
              if (customer.phone.isNotEmpty) 'Phone: ${customer.phone}',
              if ((customer.notes ?? '').isNotEmpty) customer.notes!,
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _infoBlock(
            title: 'Vehicle',
            lines: [
              vehicle.plateNumber,
              if ((vehicle.make ?? '').isNotEmpty) 'Make: ${vehicle.make}',
              if ((vehicle.model ?? '').isNotEmpty) 'Model: ${vehicle.model}',
              if (vehicle.year != null) 'Year: ${vehicle.year}',
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoBlock({
    required String title,
    required List<String> lines,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...lines.map((line) => pw.Text(line, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  static pw.Widget _lineItemsTable({
    required List<LineItem> items,
  }) {
    if (items.isEmpty) {
      return pw.Text(
        'No line items added yet.',
        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
      );
    }
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300),
        bottom: pw.BorderSide(color: PdfColors.grey400),
        top: pw.BorderSide(color: PdfColors.grey400),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeader('Description'),
            _tableHeader('Qty'),
            _tableHeader('Rate'),
            _tableHeader('Total'),
          ],
        ),
        ...items.map(
          (item) => pw.TableRow(
            children: [
              _tableCell(item.name),
              _tableCell(_formatNumber(item.qty)),
              _tableCell(_formatMoney(item.rate)),
              _tableCell(_formatMoney(item.total)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        value,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  static pw.Widget _tableCell(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static pw.Widget _totalsSection({
    required num subtotal,
    required num discountAmount,
    required num vatAmount,
    required num total,
  }) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _totalLine('Subtotal', subtotal),
            if (discountAmount > 0) _totalLine('Discount', -discountAmount),
            _totalLine('VAT', vatAmount),
            pw.Divider(color: PdfColors.grey400),
            _totalLine('Grand Total', total, bold: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _paymentSummary({
    required num paid,
    required num balance,
  }) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _totalLine('Paid', paid),
            _totalLine('Balance', balance, bold: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _totalLine(String label, num value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: 10,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(_formatMoney(value), style: style),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Payment methods: Cash, Card, Bank Transfer',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.only(right: 24),
                height: 1,
                color: PdfColors.grey400,
              ),
            ),
            pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  static List<LineItem> _mergeLineItems({
    required List<LineItem> laborItems,
    required List<LineItem> partItems,
  }) {
    return [
      ...laborItems.map(
        (item) => LineItem(
          name: 'Labor: ${item.name}',
          qty: item.qty,
          rate: item.rate,
          total: item.total,
        ),
      ),
      ...partItems.map(
        (item) => LineItem(
          name: 'Part: ${item.name}',
          qty: item.qty,
          rate: item.rate,
          total: item.total,
        ),
      ),
    ];
  }

  static String _formatMoney(num value) => value.toStringAsFixed(2);

  static String _formatNumber(num value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static Future<String> _saveTempPdf(String prefix, Uint8List bytes) async {
    final dir = await Directory.systemTemp.createTemp('garage-mvp-');
    final file = File('${dir.path}/$prefix.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
