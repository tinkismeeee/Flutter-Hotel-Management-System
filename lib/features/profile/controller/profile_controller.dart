import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class ProfileController {
  final http.Client client;

  ProfileController({http.Client? client}) : client = client ?? apiClient;

  Future<UserModel> updateProfile({
    required UserModel currentUser,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String dateOfBirth,
  }) async {
    if (currentUser.userId.isEmpty) {
      throw Exception('Customer ID is missing.');
    }

    late http.Response response;
    try {
      response = await client
          .put(
            Uri.parse(ApiEndpoints.customerById(currentUser.userId)),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email.trim().toLowerCase(),
              'first_name': firstName.trim(),
              'last_name': lastName.trim(),
              'phone_number': phone.trim(),
              'address': address.trim(),
              'date_of_birth': dateOfBirth.trim().isEmpty
                  ? null
                  : dateOfBirth.trim(),
              'is_active': currentUser.isActive,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Profile update timed out.');
    } on http.ClientException {
      throw Exception('Cannot connect to the backend.');
    }

    dynamic data;
    try {
      data = json.decode(response.body);
    } on FormatException {
      throw Exception('Backend returned an invalid response.');
    }

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        (data['message'] ?? data['error'])?.toString() ??
            'Unable to update profile.',
      );
    }

    final userJson = switch (data) {
      {'user': Map<String, dynamic> user} => user,
      {'data': Map<String, dynamic> user} => user,
      _ => data,
    };
    final updatedUser = UserModel.fromJson(userJson);

    return updatedUser.copyWith(
      password: currentUser.password,
      idCardFont: currentUser.idCardFont,
      idCardBack: currentUser.idCardBack,
    );
  }
}
