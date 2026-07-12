import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('adds ngrok bypass header to every request', () async {
    final inner = MockClient((request) async {
      expect(request.headers[ngrokSkipBrowserWarningHeader], 'true');
      return http.Response('{}', 200);
    });
    final client = ApiClient(inner);

    await client.get(
      Uri.parse('https://example.ngrok-free.app/api/rooms'),
      headers: const {ngrokSkipBrowserWarningHeader: 'false'},
    );

    client.close();
  });
}
