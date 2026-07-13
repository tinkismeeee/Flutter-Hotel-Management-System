import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/const/api_endpoints.dart';
import '../models/room_type.dart';
import 'api_response.dart';

class RoomTypeService {
  static const String baseUrl = ApiEndpoints.roomTypes;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<RoomType>> getRoomTypes() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RoomType.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách loại phòng');
    }
  }

  static Future<bool> addRoomType({
    required String name,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({'name': name, 'description': description}),
    );

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> updateRoomType({
    required int id,
    required String name,
    required String description,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({'name': name, 'description': description}),
    );

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> deleteRoomType(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    return isSuccessfulStatus(response.statusCode);
  }
}
