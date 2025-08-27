// video_detection_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class VideoDetectionService {
  static const String baseUrl =
      'YOUR_BACKEND_URL'; // Replace with your actual backend URL

  // Upload video for detection
  static Future<Map<String, dynamic>> uploadVideoForDetection(
    File videoFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/video-detection/upload'),
      );

      // Add video file
      request.files.add(
        await http.MultipartFile.fromPath('video', videoFile.path),
      );

      // Add headers if needed
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        // Add authorization headers if required
        // 'Authorization': 'Bearer YOUR_TOKEN',
      });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Send frame for live detection
  static Future<Map<String, dynamic>> sendFrameForDetection(
    Uint8List frameBytes,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/video-detection/live'),
      );

      // Add frame data
      request.files.add(
        http.MultipartFile.fromBytes(
          'frame',
          frameBytes,
          filename: 'frame.jpg',
        ),
      );

      // Add headers if needed
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        // Add authorization headers if required
        // 'Authorization': 'Bearer YOUR_TOKEN',
      });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Frame detection failed: $e');
    }
  }

  // Get supported video formats
  static Future<Map<String, dynamic>> getSupportedFormats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/video-detection/formats'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization headers if required
          // 'Authorization': 'Bearer YOUR_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get formats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // Health check
  static Future<bool> checkServiceHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/video-detection/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
