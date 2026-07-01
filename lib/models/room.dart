class Room {
  final int roomId;
  final String roomNumber;
  final int roomTypeId;
  final int floor;
  final double pricePerNight;
  final int maxGuests;
  final int bedCount;
  final String description;
  final String status;
  final bool isActive;
  final String roomTypeName;

  Room({
    required this.roomId,
    required this.roomNumber,
    required this.roomTypeId,
    required this.floor,
    required this.pricePerNight,
    required this.maxGuests,
    required this.bedCount,
    required this.description,
    required this.status,
    required this.isActive,
    required this.roomTypeName,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['room_id'] ?? 0,
      roomNumber: json['room_number'] ?? '',
      roomTypeId: json['room_type_id'] ?? 0,
      floor: json['floor'] ?? 0,
      pricePerNight: double.tryParse(json['price_per_night'].toString()) ?? 0,
      maxGuests: json['max_guests'] ?? 0,
      bedCount: json['bed_count'] ?? 0,
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      isActive: json['is_active'] ?? true,
      roomTypeName: json['room_type_name'] ?? '',
    );
  }
}