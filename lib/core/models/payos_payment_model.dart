class PayOsPaymentModel {
  final int bookingId;
  final int orderCode;
  final int amount;
  final String status;
  final String checkoutUrl;
  final String qrCode;
  final DateTime? expiresAt;

  const PayOsPaymentModel({
    required this.bookingId,
    required this.orderCode,
    required this.amount,
    required this.status,
    required this.checkoutUrl,
    required this.qrCode,
    required this.expiresAt,
  });

  factory PayOsPaymentModel.fromJson(Map<String, dynamic> json) {
    return PayOsPaymentModel(
      bookingId: _asInt(json['bookingId'] ?? json['booking_id']),
      orderCode: _asInt(json['orderCode'] ?? json['order_code']),
      amount: _asInt(json['amount']),
      status: json['status']?.toString() ?? 'pending',
      checkoutUrl:
          (json['checkoutUrl'] ?? json['checkout_url'])?.toString() ?? '',
      qrCode: (json['qrCode'] ?? json['qr_code'])?.toString() ?? '',
      expiresAt: DateTime.tryParse(
        (json['expiresAt'] ?? json['expires_at'])?.toString() ?? '',
      ),
    );
  }
}

class PromotionModel {
  final String code;
  final double discountValue;
  final String scope;

  const PromotionModel({
    required this.code,
    required this.discountValue,
    required this.scope,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      code: json['promotion_code']?.toString() ?? '',
      discountValue:
          double.tryParse(json['discount_value']?.toString() ?? '') ?? 0,
      scope: json['scope']?.toString() ?? 'invoice',
    );
  }
}

int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
