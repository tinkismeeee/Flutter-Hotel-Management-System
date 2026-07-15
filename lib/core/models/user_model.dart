import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const/api_endpoints.dart';

class UserModel {
  static const _currentUserKey = 'current_user';

  final String userId;
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String dateOfBirth;
  final String idCardFont;
  final String idCardBack;
  final bool isActive;
  final bool isAdmin;

  // Constructor
  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    required this.dateOfBirth,
    this.idCardFont = "",
    this.idCardBack = "",
    this.isActive = true,
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: (json['password'] ?? json['password_hash'])?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      dateOfBirth: json['date_of_birth']?.toString() ?? '',
      idCardFont: json['id_card_front_image_url']?.toString() ?? '',
      idCardBack: json['id_card_back_image_url']?.toString() ?? '',
      isActive: json['is_active'] == true,
      isAdmin: json['is_admin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phone,
      'address': address,
      'date_of_birth': dateOfBirth,
      'is_active': isActive,
      'is_admin': isAdmin,
    };
  }

  static Future<List<UserModel>> fetchAllUsers() async {
    final response = await http.get(Uri.parse(ApiEndpoints.customer));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final usersJson = switch (jsonData) {
        List<dynamic> data => data,
        {'data': List<dynamic> data} => data,
        Map<String, dynamic> data => [data],
        _ => throw Exception('Invalid customer response'),
      };

      return usersJson
          .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to fetch users: ${response.statusCode}');
  }

  static Future<void> saveCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
  }

  static Future<UserModel?> loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson == null) return null;

    return UserModel.fromJson(json.decode(userJson) as Map<String, dynamic>);
  }

  static Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
}
