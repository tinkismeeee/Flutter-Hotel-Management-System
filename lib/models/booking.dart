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
  final List<int> roomIds;
  final List<String> roomNumbers;

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
    required this.roomIds,
    this.roomNumbers = const [],
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
      roomIds: _readRoomIds(json),
      roomNumbers: _readRoomNumbers(json),
    );
  }

  static List<int> _readRoomIds(Map<String, dynamic> json) {
    final directRoomId = _readInt(json['room_id'] ?? json['roomId']);
    if (directRoomId != null) return [directRoomId];

    final roomIds = json['room_ids'] ?? json['roomIds'];
    if (roomIds is List) {
      return roomIds.map(_readInt).whereType<int>().toList();
    }

    final rooms = json['rooms'];
    if (rooms is List) {
      return rooms
          .map((room) {
            if (room is Map<String, dynamic>) {
              return _readInt(room['room_id'] ?? room['roomId'] ?? room['id']);
            }

            return _readInt(room);
          })
          .whereType<int>()
          .toList();
    }

    return const [];
  }

  static List<String> _readRoomNumbers(Map<String, dynamic> json) {
    final direct = json['room_number'] ?? json['roomNumber'];
    if (direct != null && direct.toString().isNotEmpty) {
      return [direct.toString()];
    }

    final roomNumbers = json['room_numbers'] ?? json['roomNumbers'];
    if (roomNumbers is List) {
      return roomNumbers
          .map((value) => value?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();
    }

    final rooms = json['rooms'];
    if (rooms is List) {
      return rooms
          .map((room) {
            if (room is Map) {
              return room['room_number'] ?? room['roomNumber'];
            }
            return null;
          })
          .whereType<Object>()
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList();
    }

    final room = json['room'];
    if (room is Map) {
      final value = room['room_number'] ?? room['roomNumber'];
      if (value != null && value.toString().isNotEmpty) {
        return [value.toString()];
      }
    }

    return const [];
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
