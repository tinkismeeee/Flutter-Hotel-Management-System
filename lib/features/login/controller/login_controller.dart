import 'dart:convert';

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class LoginController {
  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberPassword,
  }) async {
    final response = await apiClient.post(
      Uri.parse(ApiEndpoints.customerLogin),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    final data = json.decode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid server response');
    }
    if (response.statusCode != 200) {
      throw Exception(
        (data['message'] ?? data['error'])?.toString() ??
            'Invalid email or password',
      );
    }
    final userJson = data['user'];
    if (userJson is! Map<String, dynamic>) {
      throw Exception('Invalid login response');
    }
    final user = UserModel.fromJson(userJson);

    if (rememberPassword) {
      await UserModel.saveCurrentUser(user);
    } else {
      await UserModel.clearCurrentUser();
    }

    return user;
  }
}
