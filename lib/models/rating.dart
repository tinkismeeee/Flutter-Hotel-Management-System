class HotelRating {
  final int reviewId;
  final int userId;
  final int roomId;
  final int bookingId;
  final int rating;
  final String comment;
  final String createdAt;
  final String updatedAt;
  final String userName;
  final String roomNumber;

  HotelRating({
    required this.reviewId,
    required this.userId,
    required this.roomId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
    required this.roomNumber,
  });

  factory HotelRating.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final room = json['room'];

    return HotelRating(
      reviewId: _readInt(json['review_id'] ?? json['id']),
      userId: _readInt(json['user_id']),
      roomId: _readInt(json['room_id']),
      bookingId: _readInt(json['booking_id']),
      rating: _readInt(json['rating']),
      comment: _readString(json['comment']),
      createdAt: _readString(json['created_at'] ?? json['createdAt']),
      updatedAt: _readString(json['updated_at'] ?? json['updatedAt']),
      userName: _readString(
        json['user_name'] ??
            json['customer_name'] ??
            (user is Map ? user['full_name'] ?? user['name'] : null),
      ),
      roomNumber: _readString(
        json['room_number'] ?? (room is Map ? room['room_number'] : null),
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _readString(dynamic value) {
    return value?.toString() ?? '';
  }
}
