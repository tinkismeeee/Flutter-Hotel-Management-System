import 'package:http/http.dart' as http;

const ngrokSkipBrowserWarningHeader = 'ngrok-skip-browser-warning';

class ApiClient extends http.BaseClient {
  final http.Client _inner;

  ApiClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.host.endsWith('.ngrok-free.app') ||
        request.url.host.endsWith('.ngrok.io')) {
      request.headers[ngrokSkipBrowserWarningHeader] = 'true';
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final apiClient = ApiClient();
