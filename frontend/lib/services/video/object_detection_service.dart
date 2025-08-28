import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:listen_iq/models/detection_result.dart';
import 'package:listen_iq/services/ml_service.dart';
import 'package:onnxruntime/onnxruntime.dart';

class ObjectDetectionService extends MLService {
  static const String modelPath = 'assets/models/object_detection_model.onnx';
  static const String labelsPath = 'assets/labels/object_labels.txt';

  late String _inputName;
  late String _outputName;

  @override
  Future<void> initialize(String modelPath, String labelsPath) async {
    await super.initialize(modelPath, labelsPath);

    if (session != null) {
      // Get input and output names
      _inputName = session!.inputNames.first;
      _outputName = session!.outputNames.first;
      print('Input name: $_inputName');
      print('Output name: $_outputName');
    }
  }

  Future<List<DetectionResult>> detectObjects(img.Image image) async {
    if (session == null || labels == null) {
      throw Exception('Model not initialized');
    }

    try {
      // Preprocess image
      final preprocessedData = _preprocessImage(image);

      // Create input tensor
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        preprocessedData,
        [1, 3, 640, 640], // Typical YOLO input shape
      );

      // Run inference
      final outputs = session!.run(OrtRunOptions(), {_inputName: inputTensor});

      // Get output tensor
      final outputTensor = outputs[0];
      final outputData = outputTensor?.value as List<List<double>>?;

      // Parse results
      return outputData != null ? _parseDetectionResults(outputData) : [];
    } catch (e) {
      print('Error during object detection: $e');
      return [];
    }
  }

  Float32List _preprocessImage(img.Image image) {
    // Resize image to model input size (typically 640x640 for YOLO models)
    final resized = img.copyResize(image, width: 640, height: 640);

    // Convert to float32 and normalize (0-1)
    final imageData = Float32List(3 * 640 * 640);
    int pixelIndex = 0;

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = resized.getPixel(x, y);
        // RGB format, normalized to 0-1
        imageData[pixelIndex] = pixel.r / 255.0; // R
        imageData[pixelIndex + 640 * 640] = pixel.g / 255.0; // G
        imageData[pixelIndex + 2 * 640 * 640] = pixel.b / 255.0; // B
        pixelIndex++;
      }
    }

    return imageData;
  }

  List<DetectionResult> _parseDetectionResults(List<List<double>> outputData) {
    final results = <DetectionResult>[];

    // Parse YOLO-style output (adjust based on your model format)
    // Typical format: [batch, detections, (x, y, w, h, confidence, class_probs...)]
    for (final detection in outputData) {
      if (detection.length < 5) continue;

      final confidence = detection[4];
      if (confidence > 0.5) {
        // Find class with highest probability
        double maxClassProb = 0;
        int maxClassIndex = 0;

        for (int i = 5; i < detection.length; i++) {
          if (detection[i] > maxClassProb) {
            maxClassProb = detection[i];
            maxClassIndex = i - 5;
          }
        }

        final totalConfidence = confidence * maxClassProb;
        if (totalConfidence > 0.3 && maxClassIndex < labels!.length) {
          // Convert center coordinates to corner coordinates
          final centerX = detection[0];
          final centerY = detection[1];
          final width = detection[2];
          final height = detection[3];

          results.add(
            DetectionResult(
              label: labels![maxClassIndex],
              confidence: totalConfidence,
              boundingBox: Rect.fromCenter(
                center: Offset(centerX, centerY),
                width: width,
                height: height,
              ),
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    }

    return results;
  }
}
