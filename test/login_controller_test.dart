import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hotel_system_management/core/const/api_endpoints.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/login/controller/login_controller.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const testPassword = 'local-test-password';
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
      adminPassword: testPassword,
      post: (uri, {headers, body, encoding}) async {
        postCalls++;
        throw StateError('HTTP must not run');
      },
    );

    final user = await controller.login(
      email: 'admin@gmail.com',
      password: testPassword,
      rememberPassword: true,
    );

    expect(postCalls, 0);
    expect(user.email, 'admin@gmail.com');
    expect(user.isAdmin, isTrue);
    expect((await UserModel.loadCurrentUser())?.isAdmin, isTrue);
  });

  test('local admin login respects disabled session persistence', () async {
    final controller = LoginController(
      adminPassword: testPassword,
      post: (uri, {headers, body, encoding}) async =>
          throw StateError('HTTP must not run'),
    );

    final user = await controller.login(
      email: 'admin@gmail.com',
      password: testPassword,
      rememberPassword: false,
    );

    expect(user.isAdmin, isTrue);
    expect(await UserModel.loadCurrentUser(), isNull);
  });

  test('wrong local admin password continues to backend login', () async {
    var postCalls = 0;
    final controller = LoginController(
      adminPassword: testPassword,
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
    expect(postCalls, 2);
  });

  test('UserModel persistence preserves isAdmin', () async {
    final user = UserModel.fromJson({...userJson, 'is_admin': true});

    await UserModel.saveCurrentUser(user);

    expect((await UserModel.loadCurrentUser())?.isAdmin, isTrue);
  });

  test('customer 401 falls back to staff login', () async {
    final postedUris = <String>[];
    final controller = LoginController(
      post: (uri, {headers, body, encoding}) async {
        postedUris.add(uri.toString());
        if (uri.toString() == ApiEndpoints.customerLogin) {
          return http.Response(
            jsonEncode({'message': 'Invalid email or password'}),
            401,
          );
        }
        return http.Response(
          jsonEncode({
            'message': 'Login successful',
            'user': {...userJson, 'is_staff': true},
          }),
          200,
        );
      },
    );

    final user = await controller.login(
      email: 'staff@example.com',
      password: testPassword,
      rememberPassword: true,
    );

    expect(postedUris, [
      ApiEndpoints.customerLogin,
      ApiEndpoints.staffLogin,
    ]);
    expect(user.isStaff, isTrue);
    expect((await UserModel.loadCurrentUser())?.isStaff, isTrue);
  });

  test('customer success does not call staff login', () async {
    final postedUris = <String>[];
    final controller = LoginController(
      post: (uri, {headers, body, encoding}) async {
        postedUris.add(uri.toString());
        return http.Response(
          jsonEncode({
            'message': 'Login successful',
            'user': {...userJson, 'is_staff': true},
          }),
          200,
        );
      },
    );

    final user = await controller.login(
      email: 'customer@example.com',
      password: testPassword,
      rememberPassword: false,
    );

    expect(postedUris, [ApiEndpoints.customerLogin]);
    expect(user.isStaff, isFalse);
  });

  test('customer non-401 failure does not call staff login', () async {
    final postedUris = <String>[];
    final controller = LoginController(
      post: (uri, {headers, body, encoding}) async {
        postedUris.add(uri.toString());
        return http.Response(jsonEncode({'message': 'Server unavailable'}), 503);
      },
    );

    await expectLater(
      controller.login(
        email: 'staff@example.com',
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

    expect(postedUris, [ApiEndpoints.customerLogin]);
  });

  test('customer and staff 401 report the staff login error', () async {
    final controller = LoginController(
      post: (uri, {headers, body, encoding}) async => http.Response(
        jsonEncode({
          'message': uri.toString() == ApiEndpoints.customerLogin
              ? 'Customer login failed'
              : 'Invalid staff credentials',
        }),
        401,
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

  test('UserModel persistence preserves isStaff', () async {
    final user = UserModel.fromJson({...userJson, 'is_staff': true});

    await UserModel.saveCurrentUser(user);

    expect((await UserModel.loadCurrentUser())?.isStaff, isTrue);
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
      expect(user.isStaff, isFalse);
      expect((await UserModel.loadCurrentUser())?.email, 'google@example.com');
      expect((await UserModel.loadCurrentUser())?.isAdmin, isFalse);
      expect((await UserModel.loadCurrentUser())?.isStaff, isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString('current_user'),
        isNot(contains('google-id-token')),
      );
    },
  );

  test(
    'googleLoginWithIdToken posts the supplied token without native provider',
    () async {
      late Uri postedUri;
      late String postedBody;
      var tokenCalls = 0;
      final controller = LoginController(
        googleTokenProvider: () async {
          tokenCalls++;
          throw StateError('Native provider must not run');
        },
        post: (uri, {headers, body, encoding}) async {
          postedUri = uri;
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

      final user = await controller.googleLoginWithIdToken('web-id-token');

      expect(tokenCalls, 0);
      expect(postedUri.toString(), ApiEndpoints.customerGoogleLogin);
      expect(jsonDecode(postedBody), const {'idToken': 'web-id-token'});
      expect(user.email, 'google@example.com');
    },
  );

  test('googleLoginWithIdToken rejects an empty token before HTTP', () async {
    var postCalls = 0;
    final controller = LoginController(
      post: (uri, {headers, body, encoding}) async {
        postCalls++;
        throw StateError('HTTP must not run');
      },
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
    expect(postCalls, 0);
  });

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
    expect(user.isStaff, isFalse);
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
