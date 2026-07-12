class Booking {
  final int bookingId;
  final int userId;
  final String bookingDate;
  final String checkIn;
  final String checkOut;
  final String status;
  final int totalGuests;
  final int? promotionId;
  final int? numberOfDays;
  final int? numberOfNights;
  final double? totalPrice;
  final String username;

  Booking({
    required this.bookingId,
    required this.userId,
    required this.bookingDate,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.totalGuests,
    required this.promotionId,
    required this.numberOfDays,
    required this.numberOfNights,
    required this.totalPrice,
    required this.username,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      bookingDate: json['booking_date'] ?? '',
      checkIn: json['check_in'] ?? '',
      checkOut: json['check_out'] ?? '',
      status: json['status'] ?? '',
      totalGuests: json['total_guests'] ?? 0,
      promotionId: json['promotion_id'],
      numberOfDays: json['number_of_days'],
      numberOfNights: json['number_of_nights'],
      totalPrice: json['total_price'] == null
          ? null
          : double.tryParse(json['total_price'].toString()),
      username: json['username'] ?? '',
    );
  }
}