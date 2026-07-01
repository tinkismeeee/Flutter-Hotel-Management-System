import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';

class SignupController {
  Future<UserModel> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase();
    final existingUsers = await UserModel.fetchAllUsers();
    if (existingUsers.any(
      (user) => user.email.toLowerCase() == normalizedEmail,
    )) {
      throw Exception('Email already exists');
    }

    final names = fullName.trim().split(RegExp(r'\s+'));
    final firstName = names.first;
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
    final username =
        '${normalizedEmail.split('@').first}${DateTime.now().millisecondsSinceEpoch}';

    final response = await http.post(
      Uri.parse(ApiEndpoints.customer),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': normalizedEmail,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': '',
        'address': '',
        'date_of_birth': '2000-01-01',
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
