import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/const/api_endpoints.dart';
import '../models/customer.dart';

class CustomerService {
  static const String baseUrl = ApiEndpoints.customer;

  static const Map<String, String> authHeaders = {
    'Content-Type': 'application/json',
    'x-user-id': '1',
  };

  static const Map<String, String> publicHeaders = {
    'Content-Type': 'application/json',
  };

  static Future<List<Customer>> getCustomers() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: authHeaders,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Customer.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách khách hàng');
    }
  }

  static Future<bool> addCustomer({
    required String username,
    required String password,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    required String dateOfBirth,
    required String gender,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: publicHeaders,
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'address': address,
        'date_of_birth': dateOfBirth,
        'gender': gender,
      }),
    );

    print('ADD CUSTOMER STATUS: ${response.statusCode}');
    print('ADD CUSTOMER BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateCustomer({
    required int id,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String address,
    required String dateOfBirth,
    required bool isActive,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: authHeaders,
      body: jsonEncode({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'address': address,
        'date_of_birth': dateOfBirth,
        'is_active': isActive,
      }),
    );

    print('UPDATE CUSTOMER STATUS: ${response.statusCode}');
    print('UPDATE CUSTOMER BODY: ${response.body}');

    return response.statusCode == 200;
  }

  static Future<bool> deleteCustomer(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: authHeaders,
    );

    print('DELETE CUSTOMER STATUS: ${response.statusCode}');
    print('DELETE CUSTOMER BODY: ${response.body}');

    return response.statusCode == 200 || response.statusCode == 204;
  }
}
