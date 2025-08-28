import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:listen_iq/models/detection_result.dart';
import 'package:listen_iq/screens/video/widgets/detection_overlay_widget.dart';
import 'package:listen_iq/services/video/video_processing_service.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoDetectionScreen extends StatefulWidget {
  @override
  _VideoDetectionScreenState createState() => _VideoDetectionScreenState();
}

class _VideoDetectionScreenState extends State<VideoDetectionScreen> {
  CameraController? _cameraController;
  final VideoProcessingService _videoProcessingService =
      VideoProcessingService();

  List<DetectionResult> _currentObjects = [];
  ActionResult? _currentAction;
  SpeechResult? _currentSpeech;

  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _isSpeechEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _requestPermissions();
    await _initializeCamera();
    await _videoProcessingService.initialize();
    _setupStreams();
    setState(() => _isInitialized = true);
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _cameraController!.initialize();
    }
  }

  void _setupStreams() {
    _videoProcessingService.objectResults.listen((results) {
      setState(() => _currentObjects = results);
    });

    _videoProcessingService.actionResults.listen((result) {
      setState(() => _currentAction = result);
    });

    _videoProcessingService.speechResults.listen((result) {
      setState(() => _currentSpeech = result);

      // Auto-clear speech result after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _currentSpeech == result) {
          setState(() => _currentSpeech = null);
        }
      });
    });
  }

  void _startProcessing() {
    if (_cameraController?.value.isStreamingImages != true) {
      _cameraController?.startImageStream((CameraImage image) async {
        if (!_isProcessing) {
          _isProcessing = true;
          await _videoProcessingService.processFrame(image);
          _isProcessing = false;
        }
      });
    }
  }

  void _stopProcessing() {
    _cameraController?.stopImageStream();
    _videoProcessingService.stopSpeechRecognition();
  }

  void _toggleSpeechRecognition() {
    setState(() => _isSpeechEnabled = !_isSpeechEnabled);

    if (_isSpeechEnabled) {
      _videoProcessingService.resumeSpeechRecognition();
    } else {
      _videoProcessingService.pauseSpeechRecognition();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController?.value.isInitialized != true) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing ListenIQ...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ListenIQ - Video Detection'),
        backgroundColor: Colors.black87,
        actions: [
          // Speech recognition status indicator
          Container(
            margin: EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: _videoProcessingService.isSpeechListening
                        ? Colors.red
                        : Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _videoProcessingService.isSpeechListening ? 'ON' : 'OFF',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          Container(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),

          // Detection overlay
          DetectionOverlayWidget(
            objects: _currentObjects,
            action: _currentAction,
            speech: _currentSpeech,
          ),

          // Speech result display
          if (_currentSpeech != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Speech Detected',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _currentSpeech!.text,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Confidence: ${(_currentSpeech!.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Control buttons
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Start/Stop Video Processing
                FloatingActionButton(
                  onPressed: _isProcessing ? null : _startProcessing,
                  child: Icon(Icons.play_arrow),
                  backgroundColor: _isProcessing ? Colors.grey : Colors.green,
                  heroTag: "start",
                ),

                // Toggle Speech Recognition
                FloatingActionButton(
                  onPressed: _toggleSpeechRecognition,
                  child: Icon(_isSpeechEnabled ? Icons.mic : Icons.mic_off),
                  backgroundColor: _isSpeechEnabled ? Colors.blue : Colors.grey,
                  heroTag: "speech",
                ),

                // Stop Processing
                FloatingActionButton(
                  onPressed: _stopProcessing,
                  child: Icon(Icons.stop),
                  backgroundColor: Colors.red,
                  heroTag: "stop",
                ),
              ],
            ),
          ),

          // Status indicators
          Positioned(
            top: 120,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Object detection status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentObjects.isNotEmpty
                        ? Colors.green
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Objects: ${_currentObjects.length}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                SizedBox(height: 4),

                // Action detection status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentAction != null ? Colors.orange : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Action: ${_currentAction?.action ?? 'None'}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                SizedBox(height: 4),

                // Speech recognition status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _videoProcessingService.isSpeechListening
                        ? Colors.red
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Speech: ${_videoProcessingService.isSpeechListening ? 'Listening' : 'Idle'}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoProcessingService.dispose();
    super.dispose();
  }
}
