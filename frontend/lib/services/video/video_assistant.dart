// video_detection_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class VideoDetectionScreen extends StatefulWidget {
  const VideoDetectionScreen({Key? key}) : super(key: key);

  @override
  State<VideoDetectionScreen> createState() => _VideoDetectionScreenState();
}

class _VideoDetectionScreenState extends State<VideoDetectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Video upload variables
  File? _selectedVideoFile;
  VideoPlayerController? _videoController;
  bool _isProcessingVideo = false;
  Map<String, dynamic>? _uploadDetectionResults;

  // Live detection variables
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isLiveDetectionActive = false;
  Map<String, dynamic>? _liveDetectionResults;
  Timer? _detectionTimer;

  // UI state
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeCameras();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController?.dispose();
    _cameraController?.dispose();
    _detectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize cameras: $e';
      });
    }
  }

  // Video Upload Functions
  Future<void> _pickVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideoFile = File(result.files.single.path!);
          _errorMessage = '';
          _uploadDetectionResults = null;
        });
        await _initializeVideoPlayer();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking video file: $e';
      });
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_selectedVideoFile != null) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_selectedVideoFile!);
      await _videoController!.initialize();
      setState(() {});
    }
  }

  Future<void> _processUploadedVideo() async {
    if (_selectedVideoFile == null) {
      setState(() {
        _errorMessage = 'Please select a video file first';
      });
      return;
    }

    setState(() {
      _isProcessingVideo = true;
      _errorMessage = '';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('YOUR_BACKEND_URL/api/video-detection/upload'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('video', _selectedVideoFile!.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          _uploadDetectionResults = jsonResponse;
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing video: $e';
      });
    } finally {
      setState(() {
        _isProcessingVideo = false;
      });
    }
  }

  // Live Detection Functions
  Future<void> _startLiveDetection() async {
    if (_cameras == null || _cameras!.isEmpty) {
      setState(() {
        _errorMessage = 'No cameras available';
      });
      return;
    }

    try {
      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _isLiveDetectionActive = true;
        _errorMessage = '';
      });

      // Start periodic frame capture for detection
      _startDetectionLoop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error starting camera: $e';
      });
    }
  }

  void _startDetectionLoop() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) {
      if (_isLiveDetectionActive && _cameraController != null) {
        _captureAndDetect();
      }
    });
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('YOUR_BACKEND_URL/api/video-detection/live'),
      );

      request.files.add(
        http.MultipartFile.fromBytes('frame', bytes, filename: 'frame.jpg'),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          _liveDetectionResults = jsonResponse;
        });
      }

      // Clean up temporary file
      await File(image.path).delete();
    } catch (e) {
      print('Detection error: $e');
    }
  }

  void _stopLiveDetection() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;

    setState(() {
      _isLiveDetectionActive = false;
      _liveDetectionResults = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Object Detection'),
        titleTextStyle: TextStyle(
          color: Colors.grey.shade200,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFd4145a).withOpacity(0.3),
                const Color(0xFF662d8c).withOpacity(0.4),
                const Color(0xFFfbb03b).withOpacity(0.2),
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: 'Video Upload'),
            Tab(icon: Icon(Icons.videocam), text: 'Live Detection'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Error Message
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildUploadTab(), _buildLiveDetectionTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // File Upload Area
          GestureDetector(
            onTap: _pickVideoFile,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade400,
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 64,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload Video for Detection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to select video file',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Video Preview
          if (_videoController != null && _videoController!.value.isInitialized)
            Column(
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: VideoPlayer(_videoController!),
                  ),
                ),

                const SizedBox(height: 16),

                // Video Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                        });
                      },
                      icon: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        _videoController!.value.isPlaying ? 'Pause' : 'Play',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed: _isProcessingVideo
                          ? null
                          : _processUploadedVideo,
                      icon: _isProcessingVideo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                        _isProcessingVideo
                            ? 'Processing...'
                            : 'Start Detection',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Detection Results for Upload
          if (_uploadDetectionResults != null)
            _buildDetectionResults(_uploadDetectionResults!),
        ],
      ),
    );
  }

  Widget _buildLiveDetectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Detection Controls
          Center(
            child: ElevatedButton.icon(
              onPressed: _isLiveDetectionActive
                  ? _stopLiveDetection
                  : _startLiveDetection,
              icon: Icon(_isLiveDetectionActive ? Icons.stop : Icons.videocam),
              label: Text(
                _isLiveDetectionActive
                    ? 'Stop Detection'
                    : 'Start Live Detection',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLiveDetectionActive
                    ? Colors.red.shade600
                    : Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Camera Preview
          if (_isLiveDetectionActive && _cameraController != null)
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraPreview(_cameraController!),
              ),
            ),

          const SizedBox(height: 24),

          // Detection Results for Live
          if (_liveDetectionResults != null)
            _buildDetectionResults(_liveDetectionResults!),
        ],
      ),
    );
  }

  Widget _buildDetectionResults(Map<String, dynamic> results) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text(
                'Detection Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Objects Detected
          const Text(
            'Objects Detected:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          if (results['objects'] != null && results['objects'].isNotEmpty)
            Column(
              children: (results['objects'] as List).map<Widget>((obj) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        obj['name'] ?? obj['class'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${((obj['confidence'] ?? obj['score'] ?? 0) * 100).round()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No objects detected',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),

          const SizedBox(height: 16),

          // Processing Info
          const Text(
            'Processing Info:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Processing Time: ${results['processingTime'] ?? 'N/A'}'),
                Text('Total Objects: ${results['objects']?.length ?? 0}'),
                Text('Status: ${results['status'] ?? 'Completed'}'),
                if (results['timestamp'] != null)
                  Text('Timestamp: ${results['timestamp']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
