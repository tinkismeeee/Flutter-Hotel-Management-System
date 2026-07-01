class RoomModel {
  final int roomId;
  final String roomNumber;
  final int roomTypeId;
  final int floor;
  final String pricePerNight;
  final int maxGuests;
  final int bedCount;
  final String description;
  final String status;
  final bool isActive;
  final String roomTypeName;

  const RoomModel({
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

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomId: int.tryParse(json['room_id']?.toString() ?? '') ?? 0,
      roomNumber: json['room_number']?.toString() ?? '',
      roomTypeId: int.tryParse(json['room_type_id']?.toString() ?? '') ?? 0,
      floor: int.tryParse(json['floor']?.toString() ?? '') ?? 0,
      pricePerNight: json['price_per_night']?.toString() ?? '0',
      maxGuests: int.tryParse(json['max_guests']?.toString() ?? '') ?? 0,
      bedCount: int.tryParse(json['bed_count']?.toString() ?? '') ?? 0,
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isActive: json['is_active'] == true,
      roomTypeName: json['room_type_name']?.toString() ?? '',
    );
  }
}
