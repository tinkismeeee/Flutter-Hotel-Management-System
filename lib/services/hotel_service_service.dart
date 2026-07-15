import 'dart:convert';
import '../core/const/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/hotel_service.dart';
import 'api_response.dart';

class HotelServiceService {
  static const String baseUrl = ApiEndpoints.service;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<HotelService>> getServices() async {
    final response = await apiClient.get(Uri.parse(baseUrl));

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
    final response = await apiClient.post(
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

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> updateService({
    required int id,
    required String name,
    required double price,
    required bool availability,
    required String description,
  }) async {
    final response = await apiClient.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'price': price,
        'availability': availability,
        'description': description,
      }),
    );

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> deleteService(int id) async {
    final response = await apiClient.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    return isSuccessfulStatus(response.statusCode);
  }
}
