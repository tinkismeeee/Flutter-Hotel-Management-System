import 'dart:convert';
import '../core/const/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/room.dart';
import 'api_response.dart';

class RoomService {
  static const String baseUrl = ApiEndpoints.room;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<Room>> getRooms() async {
    final response = await apiClient.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Room.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách phòng');
    }
  }

  static Future<bool> addRoom({
    required String roomNumber,
    required int roomTypeId,
    required int floor,
    required double pricePerNight,
    required int maxGuests,
    required int bedCount,
    required String description,
    required String status,
    required bool isActive,
  }) async {
    final response = await apiClient.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'room_number': roomNumber,
        'room_type_id': roomTypeId,
        'floor': floor,
        'price_per_night': pricePerNight,
        'max_guests': maxGuests,
        'bed_count': bedCount,
        'description': description,
        'status': status,
        'is_active': isActive,
      }),
    );

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> updateRoom({
    required int id,
    required String roomNumber,
    required int roomTypeId,
    required int floor,
    required double pricePerNight,
    required int maxGuests,
    required int bedCount,
    required String description,
    required String status,
    required bool isActive,
  }) async {
    final response = await apiClient.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'room_number': roomNumber,
        'room_type_id': roomTypeId,
        'floor': floor,
        'price_per_night': pricePerNight,
        'max_guests': maxGuests,
        'bed_count': bedCount,
        'description': description,
        'status': status,
        'is_active': isActive,
      }),
    );

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> deleteRoom(int id) async {
    final response = await apiClient.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    return isSuccessfulStatus(response.statusCode);
  }
}
