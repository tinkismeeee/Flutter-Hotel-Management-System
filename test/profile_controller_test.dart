import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/const/api_endpoints.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/profile/controller/profile_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'updates supported profile fields and parses returned customer',
    () async {
      final currentUser = UserModel(
        userId: '7',
        username: 'brooklyn',
        email: 'old@example.com',
        password: 'internal',
        firstName: 'Old',
        lastName: 'Name',
        phone: '',
        address: '',
        dateOfBirth: '',
      );
      final controller = ProfileController(
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.toString(), ApiEndpoints.customerById('7'));
          expect(json.decode(request.body), {
            'email': 'new@example.com',
            'first_name': 'Brooklyn',
            'last_name': 'Simmons',
            'phone_number': '0901234567',
            'address': 'Ho Chi Minh City',
            'date_of_birth': '2000-01-02',
            'is_active': true,
          });

          return http.Response(
            json.encode({
              'user_id': 7,
              'username': 'brooklyn',
              'email': 'new@example.com',
              'first_name': 'Brooklyn',
              'last_name': 'Simmons',
              'phone_number': '0901234567',
              'address': 'Ho Chi Minh City',
              'date_of_birth': '2000-01-02',
              'is_active': true,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final updated = await controller.updateProfile(
        currentUser: currentUser,
        email: ' NEW@example.com ',
        firstName: ' Brooklyn ',
        lastName: ' Simmons ',
        phone: ' 0901234567 ',
        address: ' Ho Chi Minh City ',
        dateOfBirth: '2000-01-02',
      );

      expect(updated.email, 'new@example.com');
      expect(updated.firstName, 'Brooklyn');
      expect(updated.password, 'internal');
    },
  );
}
