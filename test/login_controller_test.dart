import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/const/api_endpoints.dart';
import 'package:hotel_system_management/features/login/controller/login_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'reports an offline ngrok endpoint instead of FormatException',
    () async {
      final controller = LoginController(
        client: MockClient(
          (_) async => http.Response(
            'The endpoint example.ngrok-free.app is offline.',
            404,
          ),
        ),
      );

      await expectLater(
        controller.login(
          email: 'user@example.com',
          password: 'password',
          rememberPassword: false,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('ngrok endpoint is offline'),
          ),
        ),
      );
    },
  );

  test('sends Google ID token to the backend and parses a new user', () async {
    final controller = LoginController(
      client: MockClient((request) async {
        expect(request.url.toString(), ApiEndpoints.customerGoogleLogin);
        expect(request.method, 'POST');
        expect(json.decode(request.body) as Map<String, dynamic>, {
          'idToken': 'google-id-token',
        });

        return http.Response(
          json.encode({
            'message': 'Google login successful',
            'user': {
              'user_id': 12,
              'username': 'google_user',
              'email': 'user@example.com',
              'first_name': 'Google',
              'last_name': 'User',
              'is_active': true,
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final user = await controller.loginWithGoogleIdToken('google-id-token');

    expect(user.userId, '12');
    expect(user.email, 'user@example.com');
    expect(user.isActive, isTrue);
  });
}
