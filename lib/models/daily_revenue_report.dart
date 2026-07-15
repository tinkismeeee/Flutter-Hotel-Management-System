import 'invoice.dart';

enum RevenueReportSource { reportApi, invoiceFallback }

class DailyRevenueReport {
  final DateTime date;
  final double totalRevenue;
  final double roomRevenue;
  final double serviceRevenue;
  final double vatAmount;
  final double discountAmount;
  final int invoiceCount;
  final List<Invoice> invoices;
  final RevenueReportSource source;

  const DailyRevenueReport({
    required this.date,
    required this.totalRevenue,
    required this.roomRevenue,
    required this.serviceRevenue,
    required this.vatAmount,
    required this.discountAmount,
    required this.invoiceCount,
    required this.invoices,
    required this.source,
  });

  factory DailyRevenueReport.fromInvoices(
    DateTime date,
    List<Invoice> invoices, {
    RevenueReportSource source = RevenueReportSource.invoiceFallback,
  }) {
    return DailyRevenueReport(
      date: date,
      totalRevenue: invoices.fold(0, (sum, e) => sum + e.finalAmount),
      roomRevenue: invoices.fold(0, (sum, e) => sum + e.totalRoomCost),
      serviceRevenue: invoices.fold(0, (sum, e) => sum + e.totalServiceCost),
      vatAmount: invoices.fold(0, (sum, e) => sum + e.vatAmount),
      discountAmount: invoices.fold(0, (sum, e) => sum + e.discountAmount),
      invoiceCount: invoices.length,
      invoices: invoices,
      source: source,
    );
  }

  factory DailyRevenueReport.fromJson(
    DateTime date,
    Object? json, {
    List<Invoice> fallbackInvoices = const [],
  }) {
    if (json is List) {
      return DailyRevenueReport.fromInvoices(
        date,
        _parseInvoiceList(json),
        source: RevenueReportSource.reportApi,
      );
    }

    if (json is! Map<String, dynamic>) {
      return DailyRevenueReport.fromInvoices(date, fallbackInvoices);
    }

    final nestedInvoices = _findInvoiceList(json);
    final invoices = nestedInvoices.isEmpty ? fallbackInvoices : nestedInvoices;

    return DailyRevenueReport(
      date: date,
      totalRevenue: _doubleValue(json, const [
        'total_revenue',
        'totalRevenue',
        'revenue',
        'final_amount',
        'finalAmount',
      ], fallback: invoices.fold(0, (sum, e) => sum + e.finalAmount)),
      roomRevenue: _doubleValue(json, const [
        'room_revenue',
        'roomRevenue',
        'total_room_cost',
        'totalRoomCost',
      ], fallback: invoices.fold(0, (sum, e) => sum + e.totalRoomCost)),
      serviceRevenue: _doubleValue(json, const [
        'service_revenue',
        'serviceRevenue',
        'total_service_cost',
        'totalServiceCost',
      ], fallback: invoices.fold(0, (sum, e) => sum + e.totalServiceCost)),
      vatAmount: _doubleValue(json, const [
        'vat_amount',
        'vatAmount',
        'vat',
      ], fallback: invoices.fold(0, (sum, e) => sum + e.vatAmount)),
      discountAmount: _doubleValue(json, const [
        'discount_amount',
        'discountAmount',
        'discount',
      ], fallback: invoices.fold(0, (sum, e) => sum + e.discountAmount)),
      invoiceCount: _intValue(json, const [
        'invoice_count',
        'invoiceCount',
        'total_invoices',
        'totalInvoices',
        'count',
      ], fallback: invoices.length),
      invoices: invoices,
      source: RevenueReportSource.reportApi,
    );
  }

  DailyRevenueReport copyWith({
    List<Invoice>? invoices,
    RevenueReportSource? source,
  }) {
    final nextInvoices = invoices ?? this.invoices;

    if (nextInvoices.isEmpty) {
      return DailyRevenueReport(
        date: date,
        totalRevenue: totalRevenue,
        roomRevenue: roomRevenue,
        serviceRevenue: serviceRevenue,
        vatAmount: vatAmount,
        discountAmount: discountAmount,
        invoiceCount: invoiceCount,
        invoices: nextInvoices,
        source: source ?? this.source,
      );
    }

    return DailyRevenueReport(
      date: date,
      totalRevenue: totalRevenue,
      roomRevenue: roomRevenue,
      serviceRevenue: serviceRevenue,
      vatAmount: vatAmount,
      discountAmount: discountAmount,
      invoiceCount: invoiceCount == 0 ? nextInvoices.length : invoiceCount,
      invoices: nextInvoices,
      source: source ?? this.source,
    );
  }

  static double _doubleValue(
    Map<String, dynamic> json,
    List<String> keys, {
    required double fallback,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return double.tryParse(value.toString()) ?? fallback;
      }
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return _doubleValue(data, keys, fallback: fallback);
    }

    return fallback;
  }

  static int _intValue(
    Map<String, dynamic> json,
    List<String> keys, {
    required int fallback,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return int.tryParse(value.toString()) ?? fallback;
      }
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return _intValue(data, keys, fallback: fallback);
    }

    return fallback;
  }

  static List<Invoice> _findInvoiceList(Map<String, dynamic> json) {
    for (final key in const ['invoices', 'items', 'details', 'rows']) {
      final value = json[key];
      if (value is List) return _parseInvoiceList(value);
    }

    final data = json['data'];
    if (data is List) return _parseInvoiceList(data);
    if (data is Map<String, dynamic>) return _findInvoiceList(data);

    return const [];
  }

  static List<Invoice> _parseInvoiceList(List<dynamic> items) {
    return items
        .whereType<Map<String, dynamic>>()
        .map(Invoice.fromJson)
        .toList();
  }
}
