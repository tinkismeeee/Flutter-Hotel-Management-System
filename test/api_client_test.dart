import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('adds ngrok bypass header only to ngrok requests', () async {
    final requests = <http.Request>[];
    final inner = MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 200);
    });
    final client = ApiClient(inner);

    await client.get(
      Uri.parse('https://example.ngrok-free.app/api/rooms'),
      headers: const {ngrokSkipBrowserWarningHeader: 'false'},
    );
    await client.get(Uri.parse('https://example.com/api/rooms'));

    expect(requests.first.headers[ngrokSkipBrowserWarningHeader], 'true');
    expect(
      requests.last.headers.containsKey(ngrokSkipBrowserWarningHeader),
      isFalse,
    );
    client.close();
  });
}
