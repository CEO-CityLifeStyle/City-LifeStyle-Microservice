import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../exceptions/http_exception.dart';

final _logger = getLogger('HttpClient');

class HttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final Duration timeout;

  HttpClient({this.timeout = const Duration(seconds: 30)});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      final response = await _inner.send(request).timeout(timeout);
      return response;
    } catch (e) {
      _logger.severe('HTTP request failed: $e');
      rethrow;
    }
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    try {
      final response = await _inner
          .get(url, headers: headers)
          .timeout(timeout);
      _validateResponse(response);
      return response;
    } catch (e) {
      _logger.severe('GET request failed: $e');
      rethrow;
    }
  }

  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    try {
      final response = await _inner
          .post(url, headers: headers, body: body, encoding: encoding)
          .timeout(timeout);
      _validateResponse(response);
      return response;
    } catch (e) {
      _logger.severe('POST request failed: $e');
      rethrow;
    }
  }

  @override
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    try {
      final response = await _inner
          .put(url, headers: headers, body: body, encoding: encoding)
          .timeout(timeout);
      _validateResponse(response);
      return response;
    } catch (e) {
      _logger.severe('PUT request failed: $e');
      rethrow;
    }
  }

  @override
  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    try {
      final response = await _inner
          .delete(url, headers: headers, body: body, encoding: encoding)
          .timeout(timeout);
      _validateResponse(response);
      return response;
    } catch (e) {
      _logger.severe('DELETE request failed: $e');
      rethrow;
    }
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode >= 400) {
      Map<String, dynamic> body;
      try {
        body = json.decode(response.body);
      } catch (e) {
        body = {'message': 'Unknown error occurred'};
      }

      throw HttpException(
        body['message'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  void close() {
    _inner.close();
  }
}

final httpClient = HttpClient();
