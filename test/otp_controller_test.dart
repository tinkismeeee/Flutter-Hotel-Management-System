import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/features/otp/controller/otp_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends email when requesting an OTP', () async {
    final controller = OtpController(
      client: MockClient((request) async {
        expect(request.url.path, '/send-otp');
        expect(request.body, '{"email":"tinhisme1@gmail.com"}');
        return http.Response('{"message":"OTP sent successfully!"}', 200);
      }),
    );

    expect(
      await controller.sendOtp('tinhisme1@gmail.com'),
      'OTP sent successfully!',
    );
  });

  test('returns server error when OTP is invalid', () async {
    final controller = OtpController(
      client: MockClient(
        (_) async => http.Response(
          '{"success":false,"message":"Please enter the valid OTP code"}',
          400,
        ),
      ),
    );

    await expectLater(
      controller.verifyOtp(email: 'user@example.com', otp: '1234'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Please enter the valid OTP code'),
        ),
      ),
    );
  });
}
