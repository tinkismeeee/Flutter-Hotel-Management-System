import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/room.dart';

class RoomService {
  static const String baseUrl = 'http://143.198.221.127:5678/api/rooms';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<Room>> getRooms() async {
    final response = await http.get(Uri.parse(baseUrl));

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
    final response = await http.post(
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

    print('ADD ROOM STATUS: ${response.statusCode}');
    print('ADD ROOM BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 201;
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
    final response = await http.put(
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

    print('UPDATE ROOM STATUS: ${response.statusCode}');
    print('UPDATE ROOM BODY: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<bool> deleteRoom(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    print('DELETE ROOM STATUS: ${response.statusCode}');
    print('DELETE ROOM BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 204;
  }
}