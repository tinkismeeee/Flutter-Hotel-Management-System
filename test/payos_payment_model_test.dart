import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/payos_payment_model.dart';

void main() {
  test('parses create-booking PayOS response', () {
    final payment = PayOsPaymentModel.fromJson({
      'bookingId': 42,
      'orderCode': 123456789,
      'amount': 1089000,
      'checkoutUrl': 'https://pay.payos.vn/web/abc',
      'qrCode': '000201010212...',
      'expiresAt': '2026-07-12T03:00:00.000Z',
    });

    expect(payment.bookingId, 42);
    expect(payment.status, 'pending');
    expect(payment.qrCode, isNotEmpty);
  });

  test('parses payment-status response', () {
    final payment = PayOsPaymentModel.fromJson({
      'booking_id': 42,
      'order_code': '123456789',
      'amount': '1089000',
      'status': 'paid',
      'checkout_url': 'https://pay.payos.vn/web/abc',
      'qr_code': '000201010212...',
      'expires_at': '2026-07-12T03:00:00.000Z',
    });

    expect(payment.orderCode, 123456789);
    expect(payment.amount, 1089000);
    expect(payment.status, 'paid');
  });
}
