class RoomType {
  final int roomTypeId;
  final String name;
  final String description;

  RoomType({
    required this.roomTypeId,
    required this.name,
    required this.description,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    return RoomType(
      roomTypeId: json['room_type_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}