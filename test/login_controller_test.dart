import 'package:flutter_test/flutter_test.dart';
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
}
