import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/user_booking_model.dart';

void main() {
  test('parses booking with room and payment', () {
    final booking = UserBookingModel.fromJson({
      'booking_id': 21,
      'user_id': 4,
      'booking_status': 'pending_payment',
      'check_in': '2026-07-20T00:00:00.000Z',
      'check_out': '2026-07-22T00:00:00.000Z',
      'total_guests': 2,
      'number_of_nights': 2,
      'total_price': '2200.00',
      'room': {
        'room_id': 8,
        'room_number': '108',
        'room_type_id': 1,
        'floor': 4,
        'price_per_night': '1000.00',
        'max_guests': 3,
        'bed_count': 3,
        'description': 'Standard room',
        'status': 'booked',
        'is_active': true,
        'room_type_name': 'Standard',
      },
      'payment': {
        'booking_id': 21,
        'order_code': 803053749039,
        'amount': 2200,
        'status': 'pending',
        'checkout_url': 'https://pay.payos.vn/example',
        'qr_code': 'qr-data',
        'expires_at': '2026-07-20T00:00:00.000Z',
      },
    });

    expect(booking.bookingId, 21);
    expect(booking.room.roomNumber, '108');
    expect(booking.payment.status, 'pending');
    expect(booking.numberOfNights, 2);
  });
}
