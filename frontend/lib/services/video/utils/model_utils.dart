import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ModelUtils {
  // Load ONNX model from assets
  static Future<String> loadModelFromAssets(String assetPath) async {
    try {
      final modelData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/${assetPath.split('/').last}');

      await modelFile.writeAsBytes(modelData.buffer.asUint8List());
      return modelFile.path;
    } catch (e) {
      throw Exception('Failed to load model from assets: $e');
    }
  }

  // Load labels from assets
  static Future<List<String>> loadLabelsFromAssets(String assetPath) async {
    try {
      final labelData = await rootBundle.loadString(assetPath);
      return labelData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to load labels from assets: $e');
    }
  }

  // Preprocess image for object detection (YOLO format)
  static Float32List preprocessImageForObjectDetection(
    Uint8List imageBytes,
    int width,
    int height, {
    bool normalize = true,
    double normalizeMin = 0.0,
    double normalizeMax = 1.0,
  }) {
    final inputData = Float32List(3 * width * height);

    // Assuming RGB format: [R, G, B, R, G, B, ...]
    for (int i = 0; i < imageBytes.length; i += 3) {
      final pixelIndex = i ~/ 3;
      final r = imageBytes[i].toDouble();
      final g = imageBytes[i + 1].toDouble();
      final b = imageBytes[i + 2].toDouble();

      if (normalize) {
        // Normalize to [normalizeMin, normalizeMax] range
        final normalizedR =
            (r / 255.0) * (normalizeMax - normalizeMin) + normalizeMin;
        final normalizedG =
            (g / 255.0) * (normalizeMax - normalizeMin) + normalizeMin;
        final normalizedB =
            (b / 255.0) * (normalizeMax - normalizeMin) + normalizeMin;

        // ONNX models often expect CHW format (Channel, Height, Width)
        inputData[pixelIndex] = normalizedR; // R channel
        inputData[pixelIndex + width * height] = normalizedG; // G channel
        inputData[pixelIndex + 2 * width * height] = normalizedB; // B channel
      } else {
        inputData[pixelIndex] = r;
        inputData[pixelIndex + width * height] = g;
        inputData[pixelIndex + 2 * width * height] = b;
      }
    }

    return inputData;
  }

  // Preprocess frame sequence for action recognition
  static Float32List preprocessFrameSequenceForActionRecognition(
    List<Uint8List> frameBytes,
    int frameCount,
    int width,
    int height, {
    bool normalize = true,
    double normalizeMin = -1.0,
    double normalizeMax = 1.0,
  }) {
    final inputData = Float32List(frameCount * 3 * width * height);

    for (int f = 0; f < frameCount && f < frameBytes.length; f++) {
      final frame = frameBytes[f];
      final frameOffset = f * 3 * width * height;

      for (int i = 0; i < frame.length && i < width * height * 3; i += 3) {
        final pixelIndex = i ~/ 3;
        final r = frame[i].toDouble();
        final g = frame[i + 1].toDouble();
        final b = frame[i + 2].toDouble();

        if (normalize) {
          final normalizedR =
              (r / 255.0) * (normalizeMax - normalizeMin) + normalizeMin;
          final normalizedG =
              (g / 255.0) * (normalizeMax - normalizeMin) + normalizeMin;
          final normalizedB =
              (b / 255.0) * (normalizeMax - normalizeMin) + normalizeMin;

          inputData[frameOffset + pixelIndex] = normalizedR;
          inputData[frameOffset + pixelIndex + width * height] = normalizedG;
          inputData[frameOffset + pixelIndex + 2 * width * height] =
              normalizedB;
        } else {
          inputData[frameOffset + pixelIndex] = r;
          inputData[frameOffset + pixelIndex + width * height] = g;
          inputData[frameOffset + pixelIndex + 2 * width * height] = b;
        }
      }
    }

    return inputData;
  }

  // Parse YOLO output format
  static List<Map<String, dynamic>> parseYOLOOutput(
    List<List<double>> output,
    List<String> labels,
    double confidenceThreshold,
    double nmsThreshold,
  ) {
    final detections = <Map<String, dynamic>>[];

    for (final detection in output) {
      if (detection.length < 5) continue;

      final x = detection[0];
      final y = detection[1];
      final w = detection[2];
      final h = detection[3];
      final objectness = detection[4];

      if (objectness < confidenceThreshold) continue;

      // Find best class
      double maxClassScore = 0;
      int maxClassIndex = 0;

      for (int i = 5; i < detection.length; i++) {
        if (detection[i] > maxClassScore) {
          maxClassScore = detection[i];
          maxClassIndex = i - 5;
        }
      }

      final confidence = objectness * maxClassScore;
      if (confidence < confidenceThreshold) continue;

      detections.add({
        'x': x,
        'y': y,
        'width': w,
        'height': h,
        'confidence': confidence,
        'classIndex': maxClassIndex,
        'className': maxClassIndex < labels.length
            ? labels[maxClassIndex]
            : 'Unknown',
      });
    }

    // Apply Non-Maximum Suppression
    return _applyNMS(detections, nmsThreshold);
  }

  // Non-Maximum Suppression
  static List<Map<String, dynamic>> _applyNMS(
    List<Map<String, dynamic>> detections,
    double nmsThreshold,
  ) {
    if (detections.isEmpty) return [];

    // Sort by confidence (descending)
    detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));

    final keep = <Map<String, dynamic>>[];
    final suppressed = <bool>[]
      ..length = detections.length
      ..fillRange(0, detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      keep.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        final iou = _calculateIOU(detections[i], detections[j]);
        if (iou > nmsThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return keep;
  }

  // Calculate Intersection over Union
  static double _calculateIOU(
    Map<String, dynamic> box1,
    Map<String, dynamic> box2,
  ) {
    final x1 = box1['x'] - box1['width'] / 2;
    final y1 = box1['y'] - box1['height'] / 2;
    final x2 = box1['x'] + box1['width'] / 2;
    final y2 = box1['y'] + box1['height'] / 2;

    final x3 = box2['x'] - box2['width'] / 2;
    final y3 = box2['y'] - box2['height'] / 2;
    final x4 = box2['x'] + box2['width'] / 2;
    final y4 = box2['y'] + box2['height'] / 2;

    final intersectionX1 = x1 > x3 ? x1 : x3;
    final intersectionY1 = y1 > y3 ? y1 : y3;
    final intersectionX2 = x2 < x4 ? x2 : x4;
    final intersectionY2 = y2 < y4 ? y2 : y4;

    if (intersectionX2 <= intersectionX1 || intersectionY2 <= intersectionY1) {
      return 0.0;
    }

    final intersectionArea =
        (intersectionX2 - intersectionX1) * (intersectionY2 - intersectionY1);
    final box1Area = box1['width'] * box1['height'];
    final box2Area = box2['width'] * box2['height'];
    final unionArea = box1Area + box2Area - intersectionArea;

    return intersectionArea / unionArea;
  }

  // Validate model input shape
  static bool validateInputShape(
    List<int> expectedShape,
    List<int> actualShape,
  ) {
    if (expectedShape.length != actualShape.length) return false;

    for (int i = 0; i < expectedShape.length; i++) {
      if (expectedShape[i] != -1 && expectedShape[i] != actualShape[i]) {
        return false;
      }
    }

    return true;
  }

  // Get model information
  static Map<String, dynamic> getModelInfo(String modelPath) {
    return {
      'path': modelPath,
      'size': File(modelPath).lengthSync(),
      'format': modelPath.split('.').last,
      'loaded': DateTime.now(),
    };
  }
}
