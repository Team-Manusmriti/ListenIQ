import 'dart:io';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

abstract class MLService {
  OrtSession? _session;
  List<String>? _labels;

  Future<void> initialize(String modelPath, String labelsPath) async {
    try {
      // Load model from assets to temporary file
      final modelData = await rootBundle.load(modelPath);
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/temp_model.onnx');
      await modelFile.writeAsBytes(modelData.buffer.asUint8List());

      // Create ONNX Runtime session
      _session = OrtSession.fromFile(modelFile, OrtSessionOptions());

      // Load labels
      final labelData = await rootBundle.loadString(labelsPath);
      _labels = labelData.split('\n').where((line) => line.isNotEmpty).toList();

      print('ONNX Model loaded successfully: $modelPath');
    } catch (e) {
      print('Error loading ONNX model: $e');
      rethrow;
    }
  }

  OrtSession? get session => _session;
  List<String>? get labels => _labels;

  void dispose() {
    _session?.release();
  }
}
