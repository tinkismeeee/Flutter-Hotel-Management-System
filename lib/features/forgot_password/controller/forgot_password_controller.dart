import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';

class ForgotPasswordController {
  Future<UserModel> findUserByEmail(String email) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.customerByEmail(Uri.encodeComponent(email))),
    );

    if (response.statusCode == 404) throw Exception('Email not found');
    if (!_isSuccess(response.statusCode)) {
      throw Exception('Failed to check email');
    }

    return UserModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> updatePassword({
    required UserModel user,
    required String password,
  }) async {
    final response = await http.put(
      Uri.parse(ApiEndpoints.customerUpdatePassword),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': user.email, 'newPassword': password}),
    );

    if (!_isSuccess(response.statusCode)) {
      throw Exception('Failed to update password');
    }
  }

  bool _isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
