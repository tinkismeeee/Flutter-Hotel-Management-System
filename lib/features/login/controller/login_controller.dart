import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

class LoginController {
  static final Future<void> _googleInitialization = GoogleSignIn.instance
      .initialize(serverClientId: ApiEndpoints.googleServerClientId);

  final http.Client client;

  LoginController({http.Client? client}) : client = client ?? apiClient;

  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberPassword,
  }) {
    return _postLogin(
      endpoint: ApiEndpoints.customerLogin,
      body: {'email': email, 'password': password},
      fallbackError: 'Invalid email or password',
    );
  }

  Future<UserModel?> loginWithGoogle() async {
    try {
      await _googleInitialization;

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw Exception('Google Sign-In is not supported on this platform.');
      }

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an ID token.');
      }

      return loginWithGoogleIdToken(idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw Exception(
          'Google Sign-In is not configured correctly for this app.',
        );
      }
      throw Exception(error.description ?? 'Unable to sign in with Google.');
    }
  }

  Future<UserModel> loginWithGoogleIdToken(String idToken) {
    return _postLogin(
      endpoint: ApiEndpoints.customerGoogleLogin,
      body: {'idToken': idToken},
      fallbackError: 'Unable to sign in with Google',
    );
  }

  Future<UserModel> _postLogin({
    required String endpoint,
    required Map<String, String> body,
    required String fallbackError,
  }) async {
    late http.Response response;
    try {
      response = await client
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Backend request timed out. Check the ngrok tunnel.');
    } on http.ClientException {
      throw Exception('Cannot connect to the backend.');
    }

    late dynamic data;
    try {
      data = json.decode(response.body);
    } on FormatException {
      if (response.statusCode >= 400) {
        throw Exception(
          'The ngrok endpoint is offline or no longer matches the app configuration.',
        );
      }
      throw Exception('Backend returned an invalid response.');
    }

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid server response');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        (data['message'] ?? data['error'])?.toString() ?? fallbackError,
      );
    }
    final userJson = data['user'];
    if (userJson is! Map<String, dynamic>) {
      throw Exception('Invalid login response');
    }
    return UserModel.fromJson(userJson);
  }
}
