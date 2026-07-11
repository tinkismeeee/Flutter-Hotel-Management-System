import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/daily_revenue_report.dart';
import '../models/invoice.dart';
import 'invoice_service.dart';

class RevenueReportService {
  static const String _baseUrl = 'http://143.198.221.127:5678/api/reports/revenue';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<DailyRevenueReport> getDailyRevenue(DateTime date) async {
    final invoices = await _getInvoicesForDate(date);

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/day').replace(
          queryParameters: {'date': formatApiDate(date)},
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = response.body.trim().isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body);

        final report = DailyRevenueReport.fromJson(
          date,
          decoded,
          fallbackInvoices: invoices,
        );

        return invoices.isEmpty ? report : report.copyWith(invoices: invoices);
      }
    } catch (_) {
      if (invoices.isNotEmpty) {
        return DailyRevenueReport.fromInvoices(date, invoices);
      }
    }

    return DailyRevenueReport.fromInvoices(date, invoices);
  }

  static Future<List<Invoice>> _getInvoicesForDate(DateTime date) async {
    try {
      final invoices = await InvoiceService.getInvoices();

      return invoices.where((invoice) {
        final invoiceDate = invoice.date;
        return invoiceDate.year == date.year &&
            invoiceDate.month == date.month &&
            invoiceDate.day == date.day;
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static String formatApiDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
