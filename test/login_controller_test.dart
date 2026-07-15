import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hotel_system_management/core/const/api_endpoints.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/core/network/api_client.dart';
import 'package:hotel_system_management/features/login/controller/login_controller.dart';
import 'package:hotel_system_management/features/login/view/login_screen.dart';
import 'package:hotel_system_management/features/otp/controller/otp_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const testPassword = 'local-test-password';
  const userJson = <String, dynamic>{
    'user_id': '42',
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

  test('local Admin skips backend and persists when remembered', () async {
    var requestCalls = 0;
    final controller = LoginController(
      adminPassword: testPassword,
      client: MockClient((_) async {
        requestCalls++;
        throw StateError('Backend must not run');
      }),
    );

    final user = await controller.login(
      email: ' ADMIN@gmail.com ',
      password: testPassword,
      rememberPassword: true,
    );

    expect(requestCalls, 0);
    expect(user.isAdmin, isTrue);
    expect((await UserModel.loadCurrentUser())?.isAdmin, isTrue);
  });

  test('local Admin clears persistence when not remembered', () async {
    await UserModel.saveCurrentUser(UserModel.fromJson(userJson));
    final controller = LoginController(
      adminPassword: testPassword,
      client: MockClient((_) async => throw StateError('Backend must not run')),
    );

    final user = await controller.login(
      email: 'admin@gmail.com',
      password: testPassword,
      rememberPassword: false,
    );

    expect(user.isAdmin, isTrue);
    expect(await UserModel.loadCurrentUser(), isNull);
  });

  test('customer 401 falls back to Staff and persists immediately', () async {
    final requestedUrls = <String>[];
    final controller = LoginController(
      client: MockClient((request) async {
        requestedUrls.add(request.url.toString());
        if (request.url.toString() == ApiEndpoints.customerLogin) {
          return http.Response(
            jsonEncode({'message': 'Invalid customer credentials'}),
            401,
          );
        }
        return http.Response(jsonEncode({'user': userJson}), 200);
      }),
    );

    final user = await controller.login(
      email: 'staff@example.com',
      password: testPassword,
      rememberPassword: true,
    );

    expect(requestedUrls, [
      ApiEndpoints.customerLogin,
      ApiEndpoints.staffLogin,
    ]);
    expect(user.isStaff, isTrue);
    expect((await UserModel.loadCurrentUser())?.isStaff, isTrue);
  });

  test('Staff clears persistence when not remembered', () async {
    await UserModel.saveCurrentUser(UserModel.fromJson(userJson));
    final controller = LoginController(
      client: MockClient((request) async {
        if (request.url.toString() == ApiEndpoints.customerLogin) {
          return http.Response('{}', 401);
        }
        return http.Response(
          jsonEncode({
            'user': {...userJson, 'is_staff': true},
          }),
          200,
        );
      }),
    );

    final user = await controller.login(
      email: 'staff@example.com',
      password: testPassword,
      rememberPassword: false,
    );

    expect(user.isStaff, isTrue);
    expect(await UserModel.loadCurrentUser(), isNull);
  });

  test('customer success does not fall back or persist before OTP', () async {
    await UserModel.saveCurrentUser(UserModel.fromJson(userJson));
    final requestedUrls = <String>[];
    final controller = LoginController(
      client: MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(
          jsonEncode({
            'user': {...userJson, 'is_staff': true},
          }),
          200,
        );
      }),
    );

    final user = await controller.login(
      email: 'customer@example.com',
      password: testPassword,
      rememberPassword: true,
    );

    expect(requestedUrls, [ApiEndpoints.customerLogin]);
    expect(user.isAdmin, isFalse);
    expect(user.isStaff, isFalse);
    expect(await UserModel.loadCurrentUser(), isNull);
  });

  test('customer non-401 failure does not call Staff login', () async {
    final requestedUrls = <String>[];
    final controller = LoginController(
      client: MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(
          jsonEncode({'message': 'Server unavailable'}),
          503,
        );
      }),
    );

    await expectLater(
      controller.login(
        email: 'user@example.com',
        password: testPassword,
        rememberPassword: false,
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Server unavailable'),
        ),
      ),
    );
    expect(requestedUrls, [ApiEndpoints.customerLogin]);
  });

  test('Staff failure reports the Staff backend message', () async {
    final controller = LoginController(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'message': request.url.toString() == ApiEndpoints.customerLogin
                ? 'Customer failed'
                : 'Invalid staff credentials',
          }),
          401,
        ),
      ),
    );

    await expectLater(
      controller.login(
        email: 'unknown@example.com',
        password: 'wrong',
        rememberPassword: false,
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Invalid staff credentials'),
        ),
      ),
    );
  });

  test('native Google login posts token and persists customer', () async {
    http.Request? request;
    final controller = LoginController(
      googleTokenProvider: () async => 'mobile-id-token',
      client: MockClient((received) async {
        request = received;
        return http.Response(jsonEncode({'user': userJson}), 200);
      }),
    );

    final user = await controller.googleLogin();

    expect(request?.url.toString(), ApiEndpoints.customerGoogleLogin);
    expect(jsonDecode(request!.body), {'idToken': 'mobile-id-token'});
    expect(user.isAdmin, isFalse);
    expect(user.isStaff, isFalse);
    expect((await UserModel.loadCurrentUser())?.email, 'user@example.com');
  });

  test('web Google login accepts 201 without native provider', () async {
    var nativeCalls = 0;
    http.Request? request;
    final controller = LoginController(
      googleTokenProvider: () async {
        nativeCalls++;
        return 'unused';
      },
      client: MockClient((received) async {
        request = received;
        return http.Response(
          jsonEncode({
            'user': {...userJson, 'is_admin': true, 'is_staff': true},
          }),
          201,
        );
      }),
    );

    final user = await controller.googleLoginWithIdToken('web-id-token');

    expect(nativeCalls, 0);
    expect(jsonDecode(request!.body), {'idToken': 'web-id-token'});
    expect(user.isAdmin, isFalse);
    expect(user.isStaff, isFalse);
    expect((await UserModel.loadCurrentUser())?.email, 'user@example.com');
  });

  test('Google login rejects an empty ID token before backend', () async {
    var requestCalls = 0;
    final controller = LoginController(
      client: MockClient((_) async {
        requestCalls++;
        throw StateError('Backend must not run');
      }),
    );

    await expectLater(
      controller.googleLoginWithIdToken('   '),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('ID token'),
        ),
      ),
    );
    expect(requestCalls, 0);
  });

  test('reports backend timeout without tunnel-specific wording', () async {
    final controller = LoginController(
      client: MockClient((_) async => throw TimeoutException('slow')),
    );

    await expectLater(
      controller.login(
        email: 'user@example.com',
        password: testPassword,
        rememberPassword: false,
      ),
      throwsA(
        isA<Exception>()
            .having(
              (error) => error.toString().toLowerCase(),
              'backend wording',
              contains('backend'),
            )
            .having(
              (error) => error.toString().toLowerCase(),
              'no ngrok wording',
              isNot(contains('ngrok')),
            ),
      ),
    );
  });

  test('reports backend connection failure clearly', () async {
    final controller = LoginController(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      controller.login(
        email: 'user@example.com',
        password: testPassword,
        rememberPassword: false,
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString().toLowerCase(),
          'message',
          allOf(contains('connect'), contains('backend')),
        ),
      ),
    );
  });

  test('reports non-JSON backend responses clearly', () async {
    final controller = LoginController(
      client: MockClient(
        (_) async => http.Response('<html>server error</html>', 502),
      ),
    );

    await expectLater(
      controller.login(
        email: 'user@example.com',
        password: testPassword,
        rememberPassword: false,
      ),
      throwsA(
        isA<Exception>()
            .having(
              (error) => error.toString().toLowerCase(),
              'server wording',
              anyOf(contains('backend'), contains('server')),
            )
            .having(
              (error) => error.toString().toLowerCase(),
              'invalid response wording',
              contains('invalid response'),
            ),
      ),
    );
  });

  testWidgets('customer persistence and callback wait for OTP verification', (
    tester,
  ) async {
    var callbackCalls = 0;
    final loginController = LoginController(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'user': userJson}), 200),
      ),
    );
    final otpController = OtpController(
      client: MockClient((request) async {
        if (request.url.toString() == ApiEndpoints.sendOtp) {
          return http.Response('{"message":"OTP sent"}', 200);
        }
        expect(request.url.toString(), ApiEndpoints.verifyOtp);
        return http.Response('{"message":"OTP verified"}', 200);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          loginController: loginController,
          otpController: otpController,
          onLoggedIn: (_) => callbackCalls++,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your email address'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      testPassword,
    );
    await tester.tap(find.text('Remember me'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(callbackCalls, 0);
    expect(await UserModel.loadCurrentUser(), isNull);

    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(callbackCalls, 1);
    expect((await UserModel.loadCurrentUser())?.email, 'user@example.com');
  });

  testWidgets('Admin routes immediately without OTP', (tester) async {
    var callbackCalls = 0;
    final loginController = LoginController(
      adminPassword: testPassword,
      client: MockClient((_) async => throw StateError('Backend must not run')),
    );
    final otpController = OtpController(
      client: MockClient((_) async => throw StateError('OTP must not run')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          loginController: loginController,
          otpController: otpController,
          onLoggedIn: (_) => callbackCalls++,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your email address'),
      'admin@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      testPassword,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(callbackCalls, 1);
    expect(find.text('Enter OTP'), findsNothing);
  });

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
