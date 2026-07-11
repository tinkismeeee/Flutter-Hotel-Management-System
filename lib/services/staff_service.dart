import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/staff.dart';

class StaffService {
  static const String baseUrl = 'http://143.198.221.127:5678/api/staff';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static Future<List<Staff>> getStaffs() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: headers,
    );

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
    final response = await http.post(
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

    print('ADD STATUS: ${response.statusCode}');
    print('ADD BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateStaff({
    required int id,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required bool isActive,
  }) async {
    final response = await http.put(
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

    print('UPDATE STATUS: ${response.statusCode}');
    print('UPDATE BODY: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<bool> deleteStaff(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    print('DELETE STATUS: ${response.statusCode}');
    print('DELETE BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 204;
  }
}