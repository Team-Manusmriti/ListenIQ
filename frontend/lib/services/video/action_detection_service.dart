import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:listen_iq/models/detection_result.dart';
import 'package:listen_iq/services/ml_service.dart';
import 'package:onnxruntime/onnxruntime.dart';

class ActionDetectionService extends MLService {
  static const String modelPath = 'assets/models/action_recognition_model.onnx';
  static const String labelsPath = 'assets/labels/action_labels.txt';

  late String _inputName;
  late String _outputName;

  @override
  Future<void> initialize(String modelPath, String labelsPath) async {
    await super.initialize(modelPath, labelsPath);

    if (session != null) {
      _inputName = session!.inputNames.first;
      _outputName = session!.outputNames.first;
    }
  }

  Future<ActionResult?> detectAction(List<img.Image> frameSequence) async {
    if (session == null || labels == null) {
      throw Exception('Action model not initialized');
    }

    try {
      // Preprocess frame sequence
      final inputData = _preprocessFrameSequence(frameSequence);

      // Create input tensor
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        inputData,
        [1, 16, 224, 224, 3], // Example shape, adjust as needed
      );

      // Run inference
      final outputs = session!.run(OrtRunOptions(), {_inputName: inputTensor});
      final outputTensor = outputs[0];
      final predictions = outputTensor?.value as List<double>?;

      if (predictions != null && predictions.isNotEmpty) {
        double maxConfidence = 0;
        int maxIndex = 0;
        for (int i = 0; i < predictions.length; i++) {
          if (predictions[i] > maxConfidence) {
            maxConfidence = predictions[i];
            maxIndex = i;
          }
        }
        if (maxConfidence > 0.6 && maxIndex < labels!.length) {
          return ActionResult(
            action: labels![maxIndex],
            confidence: maxConfidence,
            timestamp: DateTime.now(),
          );
        }
      }
      return null;
    } catch (e) {
      print('Error during action detection: $e');
      return null;
    }
  }

  Float32List _preprocessFrameSequence(List<img.Image> frames) {
    // Typical action recognition models expect a sequence of frames
    // Format: [batch, frames, channels, height, width] or [batch, frames, height, width, channels]
    const int frameCount = 16; // Adjust based on your model
    const int height = 224;
    const int width = 224;
    const int channels = 3;

    final inputData = Float32List(frameCount * height * width * channels);

    // Sample frames uniformly if we have more than needed
    final selectedFrames = _sampleFrames(frames, frameCount);

    for (int f = 0; f < frameCount; f++) {
      final frame = selectedFrames[f];
      final resized = img.copyResize(frame, width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = resized.getPixel(x, y);
          final baseIndex =
              f * height * width * channels +
              y * width * channels +
              x * channels;

          // Normalize to [-1, 1] range (adjust based on your model)
          inputData[baseIndex] = (pixel.r / 127.5) - 1.0; // R
          inputData[baseIndex + 1] = (pixel.g / 127.5) - 1.0; // G
          inputData[baseIndex + 2] = (pixel.b / 127.5) - 1.0; // B
        }
      }
    }

    return inputData;
  }

  List<img.Image> _sampleFrames(List<img.Image> frames, int targetCount) {
    if (frames.length <= targetCount) {
      // Pad with last frame if not enough frames
      final result = List<img.Image>.from(frames);
      while (result.length < targetCount) {
        result.add(frames.last);
      }
      return result;
    }

    // Sample uniformly
    final step = frames.length / targetCount;
    final sampled = <img.Image>[];

    for (int i = 0; i < targetCount; i++) {
      final index = (i * step).floor().clamp(0, frames.length - 1);
      sampled.add(frames[index]);
    }

    return sampled;
  }
}
