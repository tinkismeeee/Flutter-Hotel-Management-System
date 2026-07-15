import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/invoice_model.dart';

void main() {
  test('parses invoice totals returned by the API', () {
    final invoice = InvoiceModel.fromJson({
      'invoice_id': 22,
      'booking_id': 25,
      'issue_date': '2026-07-13T00:00:00.000Z',
      'total_room_cost': '2000.00',
      'total_service_cost': '17000.00',
      'discount_amount': '5700.00',
      'vat_amount': '1330.00',
      'final_amount': '14630.00',
      'payment_method': 'payos',
      'payment_status': 'paid',
    });

    expect(invoice.invoiceId, 22);
    expect(invoice.bookingId, 25);
    expect(invoice.roomCost, 2000);
    expect(invoice.serviceCost, 17000);
    expect(invoice.discountAmount, 5700);
    expect(invoice.vatAmount, 1330);
    expect(invoice.finalAmount, 14630);
    expect(invoice.paymentStatus, 'paid');
  });
}
