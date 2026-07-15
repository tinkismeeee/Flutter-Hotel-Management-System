import 'dart:convert';
import '../core/const/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/staff.dart';
import 'api_response.dart';

class StaffService {
  static const String baseUrl = ApiEndpoints.staff;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<Staff>> getStaffs() async {
    final response = await apiClient.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Staff.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách nhân viên');
    }
  }

  static Future<bool> addStaff({
    required String username,
    required String password,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final response = await apiClient.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
      }),
    );

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> updateStaff({
    required int id,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required bool isActive,
  }) async {
    final response = await apiClient.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'is_active': isActive,
      }),
    );

    return isSuccessfulStatus(response.statusCode);
  }

  static Future<bool> deleteStaff(int id) async {
    final response = await apiClient.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    return isSuccessfulStatus(response.statusCode);
  }
}
