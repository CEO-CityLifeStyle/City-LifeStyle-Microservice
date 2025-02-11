import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HttpUtils {
  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000';
  
  static Future<Map<String, dynamic>> handleResponse(Response response) async {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data;
    } else {
      throw Exception('HTTP Error: ${response.statusCode}');
    }
  }

  static Map<String, String> getAuthHeaders(String authToken) {
    return {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    };
  }

  static Options getAuthOptions(String token) {
    return Options(
      headers: getAuthHeaders(token),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return error.response?.data['message'] ?? 'Network error occurred';
    }
    return error.toString();
  }
}
