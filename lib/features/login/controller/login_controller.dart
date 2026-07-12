import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class LoginController {
  final http.Client client;

  LoginController({http.Client? client}) : client = client ?? apiClient;

  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberPassword,
  }) async {
    late http.Response response;
    try {
      response = await client
          .post(
            Uri.parse(ApiEndpoints.customerLogin),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Backend request timed out. Check the ngrok tunnel.');
    } on http.ClientException {
      throw Exception('Cannot connect to the backend.');
    }

    late dynamic data;
    try {
      data = json.decode(response.body);
    } on FormatException {
      if (response.statusCode >= 400) {
        throw Exception(
          'The ngrok endpoint is offline or no longer matches the app configuration.',
        );
      }
      throw Exception('Backend returned an invalid response.');
    }

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
