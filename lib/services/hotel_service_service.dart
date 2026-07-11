import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hotel_service.dart';

class HotelServiceService {
  static const String baseUrl = 'http://143.198.221.127:5678/api/services';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<HotelService>> getServices() async {
    final response = await http.get(
      Uri.parse(baseUrl),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => HotelService.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách dịch vụ');
    }
  }

  static Future<bool> addService({
    required String serviceCode,
    required String name,
    required double price,
    required bool availability,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'service_code': serviceCode,
        'name': name,
        'price': price,
        'availability': availability,
        'description': description,
      }),
    );

    print('ADD SERVICE STATUS: ${response.statusCode}');
    print('ADD SERVICE BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateService({
    required int id,
    required String name,
    required double price,
    required bool availability,
    required String description,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'price': price,
        'availability': availability,
        'description': description,
      }),
    );

    print('UPDATE SERVICE STATUS: ${response.statusCode}');
    print('UPDATE SERVICE BODY: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<bool> deleteService(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    print('DELETE SERVICE STATUS: ${response.statusCode}');
    print('DELETE SERVICE BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 204;
  }
}