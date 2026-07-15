import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';

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
  static const _adminEmail = 'admin@gmail.com';
  static const _requestTimeout = Duration(seconds: 15);

  final http.Client client;
  final GoogleTokenProvider _googleTokenProvider;
  final String _adminPassword;
  late final HttpPost _post;

  LoginController({
    http.Client? client,
    HttpPost? post,
    GoogleTokenProvider? googleTokenProvider,
    String? adminPassword,
  }) : client = client ?? apiClient,
       _googleTokenProvider =
           googleTokenProvider ?? GoogleSignInTokenProvider.instance.getIdToken,
       _adminPassword =
           adminPassword ??
           const String.fromEnvironment('DEMO_ADMIN_PASSWORD') {
    _post = post ?? this.client.post;
  }

  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberPassword,
  }) async {
    if (_adminPassword.isNotEmpty &&
        email.trim().toLowerCase() == _adminEmail &&
        password == _adminPassword) {
      final admin = UserModel(
        userId: 'local-admin',
        username: 'admin',
        email: _adminEmail,
        password: '',
        firstName: 'Admin',
        lastName: '',
        phone: '',
        address: '',
        dateOfBirth: '',
        isAdmin: true,
      );
      await _persistByPreference(admin, rememberPassword);
      return admin;
    }

    final customerResponse = await _postJson(ApiEndpoints.customerLogin, {
      'email': email,
      'password': password,
    });

    if (customerResponse.statusCode == 401) {
      final staffResponse = await _postJson(ApiEndpoints.staffLogin, {
        'email': email,
        'password': password,
      });
      final staffData = _decodeResponse(staffResponse);
      _requireSuccess(staffResponse, staffData, const {200});
      final staff = _userFromResponse(
        staffData,
        invalidMessage: 'Invalid staff login response',
        isStaff: true,
      );
      await _persistByPreference(staff, rememberPassword);
      return staff;
    }

    final customerData = _decodeResponse(customerResponse);
    _requireSuccess(customerResponse, customerData, const {200});
    final customer = _userFromResponse(
      customerData,
      invalidMessage: 'Invalid customer login response',
    );
    await UserModel.clearCurrentUser();
    return customer;
  }

  Future<UserModel?> loginWithGoogle() async {
    try {
      return await googleLogin();
    } on GoogleLoginCanceled {
      return null;
    }
  }

  Future<UserModel> loginWithGoogleIdToken(String idToken) {
    return googleLoginWithIdToken(idToken);
  }

  Future<UserModel> googleLogin() async {
    final idToken = await _googleTokenProvider();
    return googleLoginWithIdToken(idToken);
  }

  Future<UserModel> googleLoginWithIdToken(String idToken) async {
    if (idToken.trim().isEmpty) {
      throw Exception('Google sign-in did not return an ID token.');
    }

    final response = await _postJson(ApiEndpoints.customerGoogleLogin, {
      'idToken': idToken,
    });
    final data = _decodeResponse(response);
    _requireSuccess(response, data, const {
      200,
      201,
    }, fallback: 'Google login failed');
    final user = _userFromResponse(
      data,
      invalidMessage: 'Invalid Google login response',
    );
    await UserModel.saveCurrentUser(user);
    return user;
  }

  Future<http.Response> _postJson(
    String endpoint,
    Map<String, String> body,
  ) async {
    try {
      return await _post(
        Uri.parse(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception('Backend request timed out. Please try again.');
    } on http.ClientException {
      throw Exception('Cannot connect to the backend server.');
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    dynamic data;
    try {
      data = json.decode(response.body);
    } on FormatException {
      throw Exception(
        'Backend returned an invalid response; the ngrok endpoint is offline '
        'or misconfigured.',
      );
    }
    if (data is! Map<String, dynamic>) {
      throw Exception('Backend server returned an invalid response.');
    }
    return data;
  }

  void _requireSuccess(
    http.Response response,
    Map<String, dynamic> data,
    Set<int> successCodes, {
    String fallback = 'Invalid email or password',
  }) {
    if (!successCodes.contains(response.statusCode)) {
      throw Exception(
        (data['message'] ?? data['error'])?.toString() ?? fallback,
      );
    }
  }

  UserModel _userFromResponse(
    Map<String, dynamic> data, {
    required String invalidMessage,
    bool isStaff = false,
  }) {
    final userJson = data['user'];
    if (userJson is! Map<String, dynamic>) {
      throw Exception(invalidMessage);
    }
    return UserModel.fromJson({
      ...userJson,
      'is_admin': false,
      'is_staff': isStaff,
    });
  }

  Future<void> _persistByPreference(
    UserModel user,
    bool rememberPassword,
  ) async {
    if (rememberPassword) {
      await UserModel.saveCurrentUser(user);
    } else {
      await UserModel.clearCurrentUser();
    }
  }
}

class GoogleSignInTokenProvider {
  static final instance = GoogleSignInTokenProvider(
    initialize: () => GoogleSignIn.instance.initialize(
      serverClientId: ApiEndpoints.googleServerClientId,
    ),
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
