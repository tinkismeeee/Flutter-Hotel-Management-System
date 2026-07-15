import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/invoice_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class InvoicePdfService {
  static Future<pw.Font>? _fontFuture;

  Future<String?> download({
    required int bookingId,
    required RoomModel room,
    required UserModel user,
    required DateTime? checkIn,
    required DateTime? checkOut,
    required int guests,
    required int nights,
  }) async {
    final invoice = await _fetchInvoice(bookingId);
    final bytes = await buildPdf(
      invoice: invoice,
      room: room,
      user: user,
      checkIn: checkIn,
      checkOut: checkOut,
      guests: guests,
      nights: nights,
    );

    try {
      return await FileSaver.instance.saveAs(
        name: 'hotel_invoice_booking_$bookingId',
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
    } on MissingPluginException {
      throw Exception('Restart the app to enable PDF downloads');
    }
  }

  Future<InvoiceModel> _fetchInvoice(int bookingId) async {
    final response = await apiClient.get(Uri.parse(ApiEndpoints.invoice));
    if (response.statusCode != 200) {
      throw Exception('Cannot load invoice');
    }

    final decoded = json.decode(response.body);
    final data = switch (decoded) {
      List<dynamic> items => items,
      {'data': List<dynamic> items} => items,
      _ => throw Exception('Invalid invoice response'),
    };

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final invoice = InvoiceModel.fromJson(item);
      if (invoice.bookingId == bookingId) return invoice;
    }
    throw Exception('Invoice is not available yet');
  }

  Future<Uint8List> buildPdf({
    required InvoiceModel invoice,
    required RoomModel room,
    required UserModel user,
    required DateTime? checkIn,
    required DateTime? checkOut,
    required int guests,
    required int nights,
  }) async {
    final font = await _loadUnicodeFont();
    final document = pw.Document(
      title: 'Hotel invoice ${invoice.invoiceId}',
      author: 'Hotel System Management',
      theme: pw.ThemeData.withFont(
        base: font,
        bold: font,
        italic: font,
        boldItalic: font,
      ),
    );
    final blue = PdfColor.fromHex('#2852AF');
    final ink = PdfColor.fromHex('#171725');
    final muted = PdfColor.fromHex('#66707A');
    final border = PdfColor.fromHex('#E8EAEC');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'HOTEL INVOICE',
                      style: pw.TextStyle(
                        color: blue,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Booking #${invoice.bookingId}',
                      style: pw.TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E8F7F1'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  invoice.paymentStatus.toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#147A55'),
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: border),
          pw.SizedBox(height: 18),
          pw.Text(
            'CUSTOMER',
            style: pw.TextStyle(
              color: blue,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          _infoRow('Customer ID', user.userId, ink, muted),
          if (user.email.trim().isNotEmpty)
            _infoRow('Email', user.email.trim(), ink, muted),
          pw.SizedBox(height: 20),
          pw.Text(
            'BOOKING DETAILS',
            style: pw.TextStyle(
              color: blue,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          _infoRow('Room', room.roomNumber, ink, muted),
          if (room.roomTypeName.trim().isNotEmpty)
            _infoRow('Room type', room.roomTypeName.trim(), ink, muted),
          if (checkIn != null) _infoRow('Check-in', _date(checkIn), ink, muted),
          if (checkOut != null)
            _infoRow('Check-out', _date(checkOut), ink, muted),
          _infoRow('Guests', guests.toString(), ink, muted),
          _infoRow('Nights', nights.toString(), ink, muted),
          if (invoice.issueDate != null)
            _infoRow('Issued', _date(invoice.issueDate!), ink, muted),
          if (invoice.paymentMethod.trim().isNotEmpty)
            _infoRow(
              'Payment method',
              invoice.paymentMethod.toUpperCase(),
              ink,
              muted,
            ),
          pw.SizedBox(height: 22),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: border),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              children: [
                _moneyRow('Room', invoice.roomCost, ink, muted),
                if (invoice.serviceCost > 0)
                  _moneyRow('Services', invoice.serviceCost, ink, muted),
                if (invoice.discountAmount > 0)
                  _moneyRow('Discount', -invoice.discountAmount, ink, muted),
                if (invoice.vatAmount > 0)
                  _moneyRow('VAT', invoice.vatAmount, ink, muted),
                pw.Divider(height: 22, color: border),
                _moneyRow(
                  'TOTAL',
                  invoice.finalAmount,
                  ink,
                  muted,
                  strong: true,
                  valueColor: blue,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Text(
            'Please keep this invoice for your records. If this invoice is incorrect, please contact our support team immediately.',
            style: pw.TextStyle(color: muted, fontSize: 10),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<pw.Font> _loadUnicodeFont() {
    return _fontFuture ??= _downloadUnicodeFont();
  }

  Future<pw.Font> _downloadUnicodeFont() async {
    final response = await apiClient.get(
      Uri.parse(
        'https://raw.githubusercontent.com/google/fonts/main/ofl/lato/Lato-Regular.ttf',
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Cannot load invoice font');
    }
    return pw.Font.ttf(ByteData.sublistView(response.bodyBytes));
  }
}

pw.Widget _infoRow(String label, String value, PdfColor ink, PdfColor muted) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(color: muted, fontSize: 10),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: ink,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _moneyRow(
  String label,
  double value,
  PdfColor ink,
  PdfColor muted, {
  bool strong = false,
  PdfColor? valueColor,
}) {
  final prefix = value < 0 ? '-' : '';
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: strong ? ink : muted,
              fontSize: strong ? 12 : 10,
              fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Text(
          '$prefix${_amount(value.abs())} VND',
          style: pw.TextStyle(
            color: valueColor ?? ink,
            fontSize: strong ? 14 : 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

String _amount(double value) {
  return value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
