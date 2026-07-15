import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class OtpController {
  final http.Client client;

  OtpController({http.Client? client}) : client = client ?? apiClient;

  Future<String> sendOtp(String email) async {
    final response = await _post(
      ApiEndpoints.sendOtp,
      {'email': email},
      connectionError: 'Không thể gửi mã OTP. Vui lòng thử lại.',
    );

    return _message(response, fallback: 'Mã OTP đã được gửi.');
  }

  Future<String> verifyOtp({required String email, required String otp}) async {
    final response = await _post(
      ApiEndpoints.verifyOtp,
      {'email': email, 'otp': otp},
      connectionError: 'Không thể xác thực OTP. Vui lòng thử lại.',
    );

    return _message(response, fallback: 'Xác thực OTP thành công.');
  }

  Future<http.Response> _post(
    String endpoint,
    Map<String, String> body, {
    required String connectionError,
  }) async {
    try {
      return await client
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Yêu cầu OTP đã hết thời gian chờ.');
    } on http.ClientException {
      throw Exception(connectionError);
    }
  }

  String _message(http.Response response, {required String fallback}) {
    dynamic data;
    try {
      data = json.decode(response.body);
    } on FormatException {
      throw Exception('Máy chủ OTP trả về dữ liệu không hợp lệ.');
    }

    final message = data is Map<String, dynamic>
        ? data['message']?.toString()
        : null;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(message ?? fallback);
    }

    return message ?? fallback;
  }
}
