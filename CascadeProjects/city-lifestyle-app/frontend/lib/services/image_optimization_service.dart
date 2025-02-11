import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'error_reporting_service.dart';
import 'cache_service.dart';

class ImageSize {
  final int width;
  final int height;

  const ImageSize(this.width, this.height);
}

class ImageOptimizationService {
  static final ImageOptimizationService _instance = ImageOptimizationService._internal();
  factory ImageOptimizationService() => _instance;

  final _errorReporting = ErrorReportingService();
  final _cache = CacheService();

  static const int maxWidth = 1920;
  static const int maxHeight = 1080;
  static const int jpegQuality = 85;
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  ImageOptimizationService._internal();

  Future<Uint8List> optimizeImage({
    required Uint8List imageData,
    required String format,
    int? quality,
    int? maxWidth,
    int? maxHeight,
    bool preserveExif = false,
  }) async {
    try {
      final img.Image? image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      final ImageSize targetSize = _calculateTargetSize(
        image.width,
        image.height,
      );

      if (_needsResize(image.width, image.height, targetSize)) {
        return await resizeImage(
          imageData,
          targetSize.width,
          targetSize.height,
        );
      }

      if (imageData.length > maxFileSize) {
        return await compressImage(imageData);
      }

      return imageData;
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'image_optimization',
          'format': format,
          'quality': quality,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
        },
      );
      rethrow;
    }
  }

  Future<Uint8List> compressImage(Uint8List imageData) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(imageData);

      final result = await FlutterImageCompress.compressWithFile(
        tempPath,
        quality: jpegQuality,
      );

      await tempFile.delete();

      if (result == null) throw Exception('Image compression failed');
      return result;
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'image_compression',
        },
      );
      rethrow;
    }
  }

  Future<Uint8List> resizeImage(
    Uint8List imageData,
    int targetWidth,
    int targetHeight,
  ) async {
    try {
      final img.Image? image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      final img.Image resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'image_resize',
        },
      );
      rethrow;
    }
  }

  ImageSize _calculateTargetSize(int width, int height) {
    if (width <= maxWidth && height <= maxHeight) {
      return ImageSize(width, height);
    }

    final double aspectRatio = width / height;
    int targetWidth = width;
    int targetHeight = height;

    if (width > maxWidth) {
      targetWidth = maxWidth;
      targetHeight = (maxWidth / aspectRatio).round();
    }

    if (targetHeight > maxHeight) {
      targetHeight = maxHeight;
      targetWidth = (maxHeight * aspectRatio).round();
    }

    return ImageSize(targetWidth, targetHeight);
  }

  bool _needsResize(int width, int height, ImageSize targetSize) {
    return width != targetSize.width || height != targetSize.height;
  }

  Future<String> optimizeAndUploadImage({
    required Uint8List imageData,
    required String fileName,
    String? format,
    int? quality,
    int? maxWidth,
    int? maxHeight,
    bool preserveExif = false,
  }) async {
    try {
      // Determine format from file extension if not provided
      final fileFormat = format ?? path.extension(fileName).toLowerCase().replaceAll('.', '');
      
      // Optimize image
      final optimized = await optimizeImage(
        imageData: imageData,
        format: fileFormat,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preserveExif: preserveExif,
      );

      // Upload optimized image
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/upload'),
        body: optimized,
        headers: {
          'Content-Type': 'application/octet-stream',
          'X-File-Name': fileName,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }

      final responseData = response.body;
      return responseData; // URL of the uploaded image
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'image_upload',
          'fileName': fileName,
          'format': format,
        },
      );
      rethrow;
    }
  }

  Future<Uint8List> fetchAndOptimizeImage(
    String url, {
    int? quality,
    int? maxWidth,
    int? maxHeight,
    bool useCache = true,
  }) async {
    try {
      // Check cache first
      if (useCache) {
        final cached = await _cache.get<Uint8List>('image_$url');
        if (cached != null) return cached;
      }

      // Fetch image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch image: ${response.statusCode}');
      }

      // Optimize image
      final format = _getFormatFromUrl(url);
      final optimized = await optimizeImage(
        imageData: response.bodyBytes,
        format: format,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      // Cache optimized image
      if (useCache) {
        await _cache.set('image_$url', optimized);
      }

      return optimized;
    } catch (e, stackTrace) {
      await _errorReporting.reportError(
        e,
        stackTrace,
        context: {
          'source': 'fetch_and_optimize',
          'url': url,
        },
      );
      rethrow;
    }
  }

  String _getFormatFromUrl(String url) {
    final extension = path.extension(url).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'jpeg';
      case '.png':
        return 'png';
      case '.webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
