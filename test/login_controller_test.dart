import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hotel_system_management/core/const/api_endpoints.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/core/network/api_client.dart';
import 'package:hotel_system_management/features/login/controller/login_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const password = 'local-test-password';
  const userJson = <String, dynamic>{
    'user_id': 42,
    'username': 'test-user',
    'email': 'user@example.com',
    'first_name': 'Test',
    'last_name': 'User',
    'is_active': true,
  };

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('uses the shared ApiClient by default', () {
    expect(identical(LoginController().client, apiClient), isTrue);
  });

  test('local admin skips backend and preserves admin role', () async {
    var requestCalls = 0;
    final controller = LoginController(
      client: MockClient((_) async {
        requestCalls++;
        throw StateError('Backend must not run');
      }),
    );

    final user = await controller.login(
      email: ' ADMIN ',
      password: '12345678',
      rememberPassword: true,
    );

    expect(requestCalls, 0);
    expect(user.isAdmin, isTrue);
    expect(user.username, 'admin');
    expect((await UserModel.loadCurrentUser())?.isAdmin, isTrue);
  });

  test('customer 401 falls back to staff login', () async {
    final requestedUrls = <String>[];
    final controller = LoginController(
      client: MockClient((request) async {
        requestedUrls.add(request.url.toString());
        if (request.url.toString() == ApiEndpoints.customerLogin) {
          return http.Response('{}', 401);
        }
        return http.Response(jsonEncode({'user': userJson}), 200);
      }),
    );

    final user = await controller.login(
      email: 'staff@example.com',
      password: password,
      rememberPassword: true,
    );

    expect(requestedUrls, [
      ApiEndpoints.customerLogin,
      ApiEndpoints.staffLogin,
    ]);
    expect(user.isStaff, isTrue);
    expect((await UserModel.loadCurrentUser())?.isStaff, isTrue);
  });

  test('customer success waits for OTP before persistence', () async {
    final controller = LoginController(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'user': userJson}), 200),
      ),
    );

    final user = await controller.login(
      email: 'user@example.com',
      password: password,
      rememberPassword: true,
    );

    expect(user.isAdmin, isFalse);
    expect(user.isStaff, isFalse);
    expect(await UserModel.loadCurrentUser(), isNull);
  });

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
          password: password,
          rememberPassword: false,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains('invalid response'),
              contains('ngrok endpoint is offline'),
            ),
          ),
        ),
      );
    },
  );

  test(
    'Google ID token uses customer backend and cannot grant staff role',
    () async {
      final controller = LoginController(
        client: MockClient((request) async {
          expect(request.url.toString(), ApiEndpoints.customerGoogleLogin);
          expect(jsonDecode(request.body), {'idToken': 'google-id-token'});
          return http.Response(
            jsonEncode({
              'user': {...userJson, 'is_admin': true, 'is_staff': true},
            }),
            201,
          );
        }),
      );

      final user = await controller.loginWithGoogleIdToken('google-id-token');

      expect(user.userId, '42');
      expect(user.isAdmin, isFalse);
      expect(user.isStaff, isFalse);
      expect((await UserModel.loadCurrentUser())?.email, 'user@example.com');
    },
  );

  test('Google adapter initializes once and preserves cancellation', () async {
    var initializeCalls = 0;
    final provider = GoogleSignInTokenProvider(
      initialize: () async => initializeCalls++,
      supportsAuthenticate: () => true,
      authenticate: () async => 'google-id-token',
    );

    expect(await provider.getIdToken(), 'google-id-token');
    expect(await provider.getIdToken(), 'google-id-token');
    expect(initializeCalls, 1);

    final canceledProvider = GoogleSignInTokenProvider(
      initialize: () async {},
      supportsAuthenticate: () => true,
      authenticate: () async => throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      ),
    );
    expect(canceledProvider.getIdToken(), throwsA(isA<GoogleLoginCanceled>()));
  });
}
