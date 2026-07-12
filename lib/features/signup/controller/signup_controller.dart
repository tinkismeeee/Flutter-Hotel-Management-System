import 'dart:convert';

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class SignupController {
  Future<UserModel> signup({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String dateOfBirth,
  }) async {
    final normalizedEmail = email.toLowerCase();
    final existingUsers = await UserModel.fetchAllUsers();
    if (existingUsers.any(
      (user) => user.email.toLowerCase() == normalizedEmail,
    )) {
      throw Exception('Email already exists');
    }
    if (existingUsers.any((user) => user.username == username)) {
      throw Exception('Username already exists');
    }

    final response = await apiClient.post(
      Uri.parse(ApiEndpoints.customer),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username.trim(),
        'email': normalizedEmail,
        'password': password,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone_number': phone.trim(),
        'address': address.trim(),
        'date_of_birth': dateOfBirth.trim(),
        'is_active': true,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create account');
    }

    final body = response.body.trim();
    if (body.isNotEmpty) {
      final jsonData = json.decode(body);
      final userJson = switch (jsonData) {
        {'data': Map<String, dynamic> data} => data,
        Map<String, dynamic> data => data,
        _ => null,
      };
      if (userJson != null) return UserModel.fromJson(userJson);
    }

    return (await UserModel.fetchAllUsers()).firstWhere(
      (user) => user.email.toLowerCase() == normalizedEmail,
      orElse: () => throw Exception('Failed to load created account'),
    );
  }
}
