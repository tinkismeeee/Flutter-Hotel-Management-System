class InvoiceModel {
  final int invoiceId;
  final int bookingId;
  final DateTime? issueDate;
  final double roomCost;
  final double serviceCost;
  final double discountAmount;
  final double vatAmount;
  final double finalAmount;
  final String paymentMethod;
  final String paymentStatus;

  const InvoiceModel({
    required this.invoiceId,
    required this.bookingId,
    required this.issueDate,
    required this.roomCost,
    required this.serviceCost,
    required this.discountAmount,
    required this.vatAmount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: _toInt(json['invoice_id']),
      bookingId: _toInt(json['booking_id']),
      issueDate: DateTime.tryParse(json['issue_date']?.toString() ?? ''),
      roomCost: _toDouble(json['total_room_cost']),
      serviceCost: _toDouble(json['total_service_cost']),
      discountAmount: _toDouble(json['discount_amount']),
      vatAmount: _toDouble(json['vat_amount'] ?? json['tax_amount']),
      finalAmount: _toDouble(json['final_amount'] ?? json['total_amount']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

double _toDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;
