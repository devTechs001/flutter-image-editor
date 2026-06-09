import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_response.dart';
import '../models/image_data.dart';
import '../utils/constants.dart';

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: AppConstants.defaultTimeout,
          receiveTimeout: AppConstants.longTimeout,
          headers: {
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        debugPrint('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  Future<AiResponse> processImage({
    required File imageFile,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'action': action,
        'parameters': jsonEncode(parameters ?? {}),
      });

      final response = await _dio.post('/api/process-image', data: formData);
      return AiResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AiResponse(
        success: false,
        error: 'Network error: ${e.message}',
      );
    } catch (e) {
      return AiResponse(
        success: false,
        error: 'Processing failed: $e',
      );
    }
  }

  Future<List<DetectedObject>> detectObjects(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post('/api/detect-objects', data: formData);
      final data = AiResponse.fromJson(response.data);
      return data.objects ?? [];
    } catch (e) {
      throw Exception('Object detection failed: $e');
    }
  }

  Future<String> recognizeText(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post('/api/recognize-text', data: formData);
      final data = AiResponse.fromJson(response.data);
      return data.text ?? '';
    } catch (e) {
      throw Exception('Text recognition failed: $e');
    }
  }

  Future<File> generateImage(String prompt, {String style = 'realistic'}) async {
    try {
      final response = await _dio.post('/api/generate-image', data: {
        'prompt': prompt,
        'style': style,
      });

      final data = AiResponse.fromJson(response.data);

      if (data.imageBase64 != null) {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/gen_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(base64Decode(data.imageBase64!));
        return file;
      }

      if (data.imageUrl != null) {
        return await _downloadFile(data.imageUrl!);
      }

      throw Exception('No image data received');
    } catch (e) {
      throw Exception('Image generation failed: $e');
    }
  }

  Future<String> generateVideo(String prompt, {
    int duration = 5,
    String aspectRatio = '16:9',
  }) async {
    try {
      final response = await _dio.post('/api/generate-video', data: {
        'prompt': prompt,
        'duration': duration,
        'aspect_ratio': aspectRatio,
      });

      final data = AiResponse.fromJson(response.data);

      if (data.videoUrl != null) {
        return data.videoUrl!;
      }

      if (data.imageUrl != null) {
        return data.imageUrl!;
      }

      throw Exception('No video URL received');
    } catch (e) {
      throw Exception('Video generation failed: $e');
    }
  }

  Future<File> removeBackground(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post('/api/remove-bg', data: formData);
      final data = AiResponse.fromJson(response.data);

      if (data.imageBase64 != null) {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/no_bg_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(base64Decode(data.imageBase64!));
        return file;
      }

      throw Exception('No image data received');
    } catch (e) {
      throw Exception('Background removal failed: $e');
    }
  }

  Future<File> transformImage(File imageFile, String prompt) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'prompt': prompt,
      });

      final response = await _dio.post('/api/img2img', data: formData);
      final data = AiResponse.fromJson(response.data);

      if (data.imageBase64 != null) {
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/transform_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(base64Decode(data.imageBase64!));
        return file;
      }

      throw Exception('No image data received');
    } catch (e) {
      throw Exception('Image transformation failed: $e');
    }
  }

  Future<String> createSlideshow(
    List<String> imagePaths, {
    bool transitions = true,
    String? musicPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'transitions': transitions,
      });

      if (musicPath != null) {
        formData.files.add(MapEntry(
          'music',
          await MultipartFile.fromFile(musicPath),
        ));
      }

      for (int i = 0; i < imagePaths.length; i++) {
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(
            imagePaths[i],
            filename: 'image_$i.${imagePaths[i].split('.').last}',
          ),
        ));
      }

      final response = await _dio.post('/api/create-slideshow', data: formData);
      return response.data['video_url'];
    } catch (e) {
      throw Exception('Slideshow creation failed: $e');
    }
  }

  Future<File> _downloadFile(String url) async {
    final tempDir = Directory.systemTemp;
    final ext = url.split('.').last.split('?').first;
    final file = File(
      '${tempDir.path}/download_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await _dio.download(url, file.path);
    return file;
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/api/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
