import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';

class UploadService {
  final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000';

  Future<String> uploadSingleImage(File imageFile, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload/single');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        return data['imageUrl'];
      } else {
        throw Exception(json.decode(responseData)['error']);
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> imageFiles, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/upload/multiple');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      for (var imageFile in imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        return List<String>.from(data['imageUrls']);
      } else {
        throw Exception(json.decode(responseData)['error']);
      }
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  Future<void> deleteImage(String imageUrl, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/upload'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'imageUrl': imageUrl}),
      );

      if (response.statusCode != 200) {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
