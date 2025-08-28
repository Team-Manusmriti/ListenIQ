import 'dart:async';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:listen_iq/models/detection_result.dart';
import 'object_detection_service.dart';
import 'action_detection_service.dart';
import 'speech_recognition_service.dart';

class VideoProcessingService {
  final ObjectDetectionService _objectDetectionService =
      ObjectDetectionService();
  final ActionDetectionService _actionDetectionService =
      ActionDetectionService();
  final SpeechRecognitionService _speechRecognitionService =
      SpeechRecognitionService();

  final List<img.Image> _frameBuffer = [];
  final int _maxFrameBuffer = 16;

  StreamController<List<DetectionResult>>? _objectResultsController;
  StreamController<ActionResult>? _actionResultsController;
  late StreamSubscription _speechSubscription;

  Stream<List<DetectionResult>> get objectResults =>
      _objectResultsController?.stream ?? const Stream.empty();

  Stream<ActionResult> get actionResults =>
      _actionResultsController?.stream ?? const Stream.empty();

  Stream<SpeechResult> get speechResults =>
      _speechRecognitionService.speechStream;

  Future<void> initialize() async {
    _objectResultsController =
        StreamController<List<DetectionResult>>.broadcast();
    _actionResultsController = StreamController<ActionResult>.broadcast();

    await Future.wait([
      _objectDetectionService.initialize(
        ObjectDetectionService.modelPath,
        ObjectDetectionService.labelsPath,
      ),
      _actionDetectionService.initialize(
        ActionDetectionService.modelPath,
        ActionDetectionService.labelsPath,
      ),
      _speechRecognitionService.initialize(),
    ]);

    // Start continuous speech recognition
    await _speechRecognitionService.startContinuousListening();
  }

  Future<void> processFrame(CameraImage cameraImage) async {
    try {
      // Convert CameraImage to img.Image
      final image = _convertCameraImage(cameraImage);
      if (image == null) return;

      // Add to frame buffer for action detection
      _frameBuffer.add(image);
      if (_frameBuffer.length > _maxFrameBuffer) {
        _frameBuffer.removeAt(0);
      }

      // Run object detection on current frame
      final objectResults = await _objectDetectionService.detectObjects(image);
      _objectResultsController?.add(objectResults);

      // Run action detection if we have enough frames
      if (_frameBuffer.length == _maxFrameBuffer) {
        final actionResult = await _actionDetectionService.detectAction(
          _frameBuffer,
        );
        if (actionResult != null) {
          _actionResultsController?.add(actionResult);
        }
      }

      // Speech recognition runs continuously in the background
      // Results are automatically streamed through speechResults stream
    } catch (e) {
      print('Error processing frame: $e');
    }
  }

  // Control speech recognition
  void pauseSpeechRecognition() {
    _speechRecognitionService.pauseListening();
  }

  void resumeSpeechRecognition() {
    _speechRecognitionService.resumeListening();
  }

  void stopSpeechRecognition() {
    _speechRecognitionService.stopListening();
  }

  // Get speech recognition status
  bool get isSpeechListening => _speechRecognitionService.isListening;
  Future<bool> get hasMicrophonePermission =>
      _speechRecognitionService.hasPermission;

  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      // Convert YUV420 to RGB
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToRGB(cameraImage);
      }
      return null;
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  img.Image _convertYUV420ToRGB(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        // YUV to RGB conversion
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  void dispose() {
    _objectDetectionService.dispose();
    _actionDetectionService.dispose();
    _speechRecognitionService.dispose();

    _objectResultsController?.close();
    _actionResultsController?.close();
  }
}
