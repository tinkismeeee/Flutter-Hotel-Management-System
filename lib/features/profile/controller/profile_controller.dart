import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class ProfileController {
  final http.Client client;

  ProfileController({http.Client? client}) : client = client ?? apiClient;

  Future<UserModel> fetchProfile(UserModel currentUser) async {
    final response = await client
        .get(Uri.parse(ApiEndpoints.customerById(currentUser.userId)))
        .timeout(const Duration(seconds: 15));
    return _userFromResponse(response, currentUser);
  }

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

    return _userFromResponse(response, currentUser);
  }

  Future<UserModel> uploadIdCards({
    required UserModel currentUser,
    String? frontPath,
    String? backPath,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse(ApiEndpoints.customerIdCards(currentUser.userId)),
    );
    if (frontPath != null) {
      request.files.add(await http.MultipartFile.fromPath('front', frontPath));
    }
    if (backPath != null) {
      request.files.add(await http.MultipartFile.fromPath('back', backPath));
    }
    final response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(seconds: 30)),
    );
    return _userFromResponse(response, currentUser);
  }

  Future<UserModel> deleteIdCardImage({
    required UserModel currentUser,
    required String side,
  }) async {
    final response = await client
        .delete(
          Uri.parse(ApiEndpoints.customerIdCardImage(currentUser.userId, side)),
        )
        .timeout(const Duration(seconds: 15));
    return _userFromResponse(response, currentUser);
  }

  UserModel _userFromResponse(http.Response response, UserModel currentUser) {
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
    return UserModel.fromJson(
      userJson,
    ).copyWith(password: currentUser.password);
  }
}
