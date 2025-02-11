import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DioClient {
  static Dio getInstance() {
    final dio = Dio();
    dio.options.baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000';
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 3);
    return dio;
  }
}
