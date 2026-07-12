class RoomReviewModel {
  final int reviewId;
  final int bookingId;
  final int userId;
  final int roomId;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final String username;
  final String firstName;
  final String lastName;

  const RoomReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.userId,
    required this.roomId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.username,
    required this.firstName,
    required this.lastName,
  });

  String get reviewerName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty
        ? fullName
        : username.isNotEmpty
        ? username
        : 'Hotel guest';
  }

  factory RoomReviewModel.fromJson(Map<String, dynamic> json) {
    return RoomReviewModel(
      reviewId: _toInt(json['review_id']),
      bookingId: _toInt(json['booking_id']),
      userId: _toInt(json['user_id']),
      roomId: _toInt(json['room_id']),
      rating: _toInt(json['rating']).clamp(1, 5),
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
