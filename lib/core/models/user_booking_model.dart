import 'payos_payment_model.dart';
import 'room_model.dart';

class UserBookingModel {
  final int bookingId;
  final int userId;
  final DateTime? bookingDate;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String bookingStatus;
  final int totalGuests;
  final int numberOfNights;
  final String totalPrice;
  final RoomModel room;
  final PayOsPaymentModel payment;

  const UserBookingModel({
    required this.bookingId,
    required this.userId,
    required this.bookingDate,
    required this.checkIn,
    required this.checkOut,
    required this.bookingStatus,
    required this.totalGuests,
    required this.numberOfNights,
    required this.totalPrice,
    required this.room,
    required this.payment,
  });

  factory UserBookingModel.fromJson(Map<String, dynamic> json) {
    final roomJson = json['room'];
    final paymentJson = json['payment'];
    if (roomJson is! Map<String, dynamic> ||
        paymentJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid booking response');
    }

    return UserBookingModel(
      bookingId: _toInt(json['booking_id']),
      userId: _toInt(json['user_id']),
      bookingDate: _toDate(json['booking_date']),
      checkIn: _toDate(json['check_in']),
      checkOut: _toDate(json['check_out']),
      bookingStatus: json['booking_status']?.toString() ?? '',
      totalGuests: _toInt(json['total_guests']),
      numberOfNights: _toInt(json['number_of_nights']),
      totalPrice: json['total_price']?.toString() ?? '0',
      room: RoomModel.fromJson(roomJson),
      payment: PayOsPaymentModel.fromJson(paymentJson),
    );
  }
}

int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

DateTime? _toDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '');
}
