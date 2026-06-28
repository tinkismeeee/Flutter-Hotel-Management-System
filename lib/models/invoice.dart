class Invoice {
  final int invoiceId;
  final int bookingId;
  final int staffId;
  final String issueDate;
  final double totalRoomCost;
  final double totalServiceCost;
  final double discountAmount;
  final double finalAmount;
  final double vatAmount;
  final String paymentMethod;
  final int? promotionId;
  final String paymentStatus;

  Invoice({
    required this.invoiceId,
    required this.bookingId,
    required this.staffId,
    required this.issueDate,
    required this.totalRoomCost,
    required this.totalServiceCost,
    required this.discountAmount,
    required this.finalAmount,
    required this.vatAmount,
    required this.paymentMethod,
    required this.promotionId,
    required this.paymentStatus,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoice_id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      staffId: json['staff_id'] ?? 0,
      issueDate: json['issue_date'] ?? '',
      totalRoomCost: double.tryParse(json['total_room_cost'].toString()) ?? 0,
      totalServiceCost:
      double.tryParse(json['total_service_cost'].toString()) ?? 0,
      discountAmount:
      double.tryParse(json['discount_amount'].toString()) ?? 0,
      finalAmount: double.tryParse(json['final_amount'].toString()) ?? 0,
      vatAmount: double.tryParse(json['vat_amount'].toString()) ?? 0,
      paymentMethod: json['payment_method'] ?? '',
      promotionId: json['promotion_id'],
      paymentStatus: json['payment_status'] ?? '',
    );
  }

  DateTime get date {
    return DateTime.tryParse(issueDate) ?? DateTime(2000);
  }
}