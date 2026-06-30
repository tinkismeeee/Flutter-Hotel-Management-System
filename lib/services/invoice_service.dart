import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/invoice.dart';

class InvoiceService {
  static const String baseUrl = 'http://143.198.221.127/api/invoices';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<Invoice>> getInvoices() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Invoice.fromJson(e)).toList();
    }

    throw Exception('Không thể tải danh sách hóa đơn');
  }
}
