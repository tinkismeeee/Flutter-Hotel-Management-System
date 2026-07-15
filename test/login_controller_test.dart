import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hotel_system_management/core/const/api_endpoints.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/login/controller/login_controller.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const userJson = <String, dynamic>{
    'user_id': '42',
    'username': 'google-user',
    'email': 'google@example.com',
    'first_name': 'Google',
    'last_name': 'User',
    'is_active': true,
  };

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('local admin login skips HTTP and persists admin session', () async {
    var postCalls = 0;
    final controller = LoginController(
      adminPassword: '12345678',
      post: (uri, {headers, body, encoding}) async {
        postCalls++;
        throw StateError('HTTP must not run');
      },
    );

    final user = await controller.login(
      email: 'admin@gmail.com',
      password: '12345678',
      rememberPassword: true,
    );

    expect(postCalls, 0);
    expect(user.email, 'admin@gmail.com');
    expect(user.isAdmin, isTrue);
    expect((await UserModel.loadCurrentUser())?.isAdmin, isTrue);
  });

  test('local admin login respects disabled session persistence', () async {
    final controller = LoginController(
      adminPassword: '12345678',
      post: (uri, {headers, body, encoding}) async =>
          throw StateError('HTTP must not run'),
    );

    final user = await controller.login(
      email: 'admin@gmail.com',
      password: '12345678',
      rememberPassword: false,
    );

    expect(user.isAdmin, isTrue);
    expect(await UserModel.loadCurrentUser(), isNull);
  });

  test('wrong local admin password continues to customer backend', () async {
    var postCalls = 0;
    final controller = LoginController(
      adminPassword: '12345678',
      post: (uri, {headers, body, encoding}) async {
        postCalls++;
        return http.Response(
          jsonEncode({'message': 'Invalid email or password'}),
          401,
        );
      },
    );

    await expectLater(
      controller.login(
        email: 'admin@gmail.com',
        password: 'wrong-password',
        rememberPassword: true,
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Invalid email or password'),
        ),
      ),
    );
    expect(postCalls, 1);
  });

  test('UserModel persistence preserves isAdmin', () async {
    final user = UserModel.fromJson({...userJson, 'is_admin': true});

    await UserModel.saveCurrentUser(user);

    expect((await UserModel.loadCurrentUser())?.isAdmin, isTrue);
  });

  test(
    'googleLogin posts the ID token and persists the returned user',
    () async {
      late Uri postedUri;
      late Map<String, String> postedHeaders;
      late String postedBody;
      var tokenCalls = 0;
      final controller = LoginController(
        googleTokenProvider: () async {
          tokenCalls++;
          return 'google-id-token';
        },
        post: (uri, {headers, body, encoding}) async {
          postedUri = uri;
          postedHeaders = headers!;
          postedBody = body! as String;
          return http.Response(
            jsonEncode(<String, Object>{
              'message': 'Login successful',
              'user': userJson,
            }),
            200,
          );
        },
      );

      final user = await controller.googleLogin();

      expect(tokenCalls, 1);
      expect(postedUri.toString(), ApiEndpoints.customerGoogleLogin);
      expect(postedHeaders, const {'Content-Type': 'application/json'});
      expect(jsonDecode(postedBody), const {'idToken': 'google-id-token'});
      expect(user.userId, '42');
      expect(user.isAdmin, isFalse);
      expect((await UserModel.loadCurrentUser())?.email, 'google@example.com');
      expect((await UserModel.loadCurrentUser())?.isAdmin, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString('current_user'),
        isNot(contains('google-id-token')),
      );
    },
  );

  test('googleLogin accepts a newly created user response', () async {
    final controller = LoginController(
      googleTokenProvider: () async => 'google-id-token',
      post: (uri, {headers, body, encoding}) async => http.Response(
        jsonEncode(<String, Object>{
          'message': 'Google login successful',
          'user': {...userJson, 'is_admin': true},
        }),
        201,
      ),
    );

    final user = await controller.googleLogin();

    expect(user.email, 'google@example.com');
    expect(user.isAdmin, isFalse);
    expect((await UserModel.loadCurrentUser())?.email, 'google@example.com');
    expect((await UserModel.loadCurrentUser())?.isAdmin, isFalse);
  });

  test('googleLogin propagates a backend message', () async {
    final controller = LoginController(
      googleTokenProvider: () async => 'google-id-token',
      post: (uri, {headers, body, encoding}) async => http.Response(
        jsonEncode({'message': 'Google account is blocked'}),
        403,
      ),
    );

    expect(
      controller.googleLogin(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Google account is blocked'),
        ),
      ),
    );
  });

  test('googleLogin preserves typed cancellation', () async {
    final controller = LoginController(
      googleTokenProvider: () async => throw const GoogleLoginCanceled(),
      post: (uri, {headers, body, encoding}) async =>
          throw StateError('HTTP must not run'),
    );

    expect(controller.googleLogin(), throwsA(isA<GoogleLoginCanceled>()));
  });

  test('Google adapter initializes exactly once', () async {
    var initializeCalls = 0;
    var authenticateCalls = 0;
    final provider = GoogleSignInTokenProvider(
      initialize: () async => initializeCalls++,
      supportsAuthenticate: () => true,
      authenticate: () async {
        authenticateCalls++;
        return 'google-id-token';
      },
    );

    expect(await provider.getIdToken(), 'google-id-token');
    expect(await provider.getIdToken(), 'google-id-token');
    expect(initializeCalls, 1);
    expect(authenticateCalls, 2);
  });

  test('Google adapter rejects unsupported authenticate', () async {
    var authenticateCalls = 0;
    final provider = GoogleSignInTokenProvider(
      initialize: () async {},
      supportsAuthenticate: () => false,
      authenticate: () async {
        authenticateCalls++;
        return 'google-id-token';
      },
    );

    expect(
      provider.getIdToken(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Google sign-in is not supported on this platform.'),
        ),
      ),
    );
    expect(authenticateCalls, 0);
  });

  test('Google adapter preserves typed cancellation', () async {
    final provider = GoogleSignInTokenProvider(
      initialize: () async {},
      supportsAuthenticate: () => true,
      authenticate: () async => throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      ),
    );

    expect(provider.getIdToken(), throwsA(isA<GoogleLoginCanceled>()));
  });

  test('Google configuration failures include provider details', () {
    expect(
      googleSignInErrorMessage(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'Invalid server client ID.',
        ),
      ),
      'Google sign-in is not configured correctly. Invalid server client ID.',
    );
    expect(
      googleSignInErrorMessage(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.providerConfigurationError,
          description: 'Google Play services unavailable.',
        ),
      ),
      'Google sign-in provider is unavailable or misconfigured. '
      'Google Play services unavailable.',
    );
  });
}
