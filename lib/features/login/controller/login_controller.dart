import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';

typedef HttpPost =
    Future<http.Response> Function(
      Uri url, {
      Map<String, String>? headers,
      Object? body,
      Encoding? encoding,
    });

typedef GoogleTokenProvider = Future<String> Function();
typedef GoogleSignInInitialize = Future<void> Function();
typedef GoogleSignInSupportsAuthenticate = bool Function();
typedef GoogleSignInAuthenticate = Future<String?> Function();

class GoogleLoginCanceled implements Exception {
  const GoogleLoginCanceled();
}

class LoginController {
  final HttpPost _post;
  final GoogleTokenProvider _googleTokenProvider;

  LoginController({HttpPost? post, GoogleTokenProvider? googleTokenProvider})
    : _post = post ?? http.post,
      _googleTokenProvider =
          googleTokenProvider ?? GoogleSignInTokenProvider.instance.getIdToken;

  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberPassword,
  }) async {
    final response = await _post(
      Uri.parse(ApiEndpoints.customerLogin),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    final data = json.decode(response.body);
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

  Future<UserModel> googleLogin() async {
    final idToken = await _googleTokenProvider();
    final response = await _post(
      Uri.parse(ApiEndpoints.customerGoogleLogin),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'idToken': idToken}),
    );
    final data = json.decode(response.body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid server response');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        (data['message'] ?? data['error'])?.toString() ?? 'Google login failed',
      );
    }
    final userJson = data['user'];
    if (userJson is! Map<String, dynamic>) {
      throw Exception('Invalid Google login response');
    }

    final user = UserModel.fromJson(userJson);
    await UserModel.saveCurrentUser(user);
    return user;
  }
}

class GoogleSignInTokenProvider {
  static const _serverClientId =
      '786154844319-e7a4pucog1mj8mugg2qsh8aeu388i1c1.apps.googleusercontent.com';
  static final instance = GoogleSignInTokenProvider(
    initialize: () =>
        GoogleSignIn.instance.initialize(serverClientId: _serverClientId),
    supportsAuthenticate: GoogleSignIn.instance.supportsAuthenticate,
    authenticate: () async {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    },
  );

  final GoogleSignInInitialize initialize;
  final GoogleSignInSupportsAuthenticate supportsAuthenticate;
  final GoogleSignInAuthenticate authenticate;
  Future<void>? _initialization;

  GoogleSignInTokenProvider({
    required this.initialize,
    required this.supportsAuthenticate,
    required this.authenticate,
  });

  Future<String> getIdToken() async {
    try {
      await (_initialization ??= Future<void>.sync(initialize));
      if (!supportsAuthenticate()) {
        throw Exception('Google sign-in is not supported on this platform.');
      }
      final idToken = await authenticate();
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google sign-in did not return an ID token. '
          'Check the OAuth server client configuration.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleLoginCanceled();
      }
      throw Exception(googleSignInErrorMessage(error));
    }
  }
}

String googleSignInErrorMessage(GoogleSignInException error) {
  final detail = error.description == null ? '' : ' ${error.description}';
  switch (error.code) {
    case GoogleSignInExceptionCode.clientConfigurationError:
      return 'Google sign-in is not configured correctly.$detail';
    case GoogleSignInExceptionCode.providerConfigurationError:
      return 'Google sign-in provider is unavailable or misconfigured.$detail';
    default:
      return error.description ?? 'Google sign-in failed. Please try again.';
  }
}
