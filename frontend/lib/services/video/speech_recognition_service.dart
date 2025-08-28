import 'dart:async';
import 'package:listen_iq/models/detection_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechRecognitionService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  StreamController<SpeechResult>? _speechController;
  Timer? _continuousListeningTimer;

  // Configuration
  final Duration _listeningDuration = const Duration(seconds: 3);
  final Duration _pauseBetweenListening = const Duration(milliseconds: 500);
  final double _confidenceThreshold = 0.3;

  Stream<SpeechResult> get speechStream =>
      _speechController?.stream ?? const Stream.empty();

  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        print('Microphone permission denied');
        return false;
      }

      // Initialize speech recognition
      _isInitialized = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: true,
      );

      if (_isInitialized) {
        _speechController = StreamController<SpeechResult>.broadcast();
        print('Speech recognition initialized successfully');
      }

      return _isInitialized;
    } catch (e) {
      print('Error initializing speech recognition: $e');
      return false;
    }
  }

  void _onSpeechStatus(String status) {
    print('Speech status: $status');

    if (status == 'done' && _isListening) {
      _isListening = false;
      // Restart listening after a short pause for continuous recognition
      _scheduleContinuousListening();
    }
  }

  void _onSpeechError(dynamic error) {
    print('Speech error: $error');
    _isListening = false;

    // Try to restart listening after error
    Future.delayed(const Duration(seconds: 1), () {
      if (_isInitialized && !_isListening) {
        _startListening();
      }
    });
  }

  Future<void> startContinuousListening() async {
    if (!_isInitialized) {
      print('Speech recognition not initialized');
      return;
    }

    await _startListening();
  }

  Future<void> _startListening() async {
    if (_isListening || !_speechToText.isAvailable) return;

    try {
      _isListening = true;
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: _listeningDuration,
        pauseFor: _pauseBetweenListening,
        partialResults: true,
        localeId: 'en_US', // Change based on your requirements
        onSoundLevelChange: (level) {
          // Optional: handle sound level changes
        },
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
    }
  }

  void _onSpeechResult(result) {
    if (result.finalResult &&
        result.confidence >= _confidenceThreshold &&
        result.recognizedWords.isNotEmpty) {
      final speechResult = SpeechResult(
        text: result.recognizedWords,
        confidence: result.confidence,
        timestamp: DateTime.now(),
      );

      _speechController?.add(speechResult);
      print(
        'Speech recognized: ${result.recognizedWords} (${result.confidence})',
      );
    }
  }

  void _scheduleContinuousListening() {
    _continuousListeningTimer?.cancel();
    _continuousListeningTimer = Timer(_pauseBetweenListening, () {
      if (_isInitialized && !_isListening) {
        _startListening();
      }
    });
  }

  Future<SpeechResult?> getSingleRecognition() async {
    if (!_isInitialized || _isListening) return null;

    final completer = Completer<SpeechResult?>();

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            if (result.confidence >= _confidenceThreshold &&
                result.recognizedWords.isNotEmpty) {
              completer.complete(
                SpeechResult(
                  text: result.recognizedWords,
                  confidence: result.confidence,
                  timestamp: DateTime.now(),
                ),
              );
            } else {
              completer.complete(null);
            }
          }
        },
        listenFor: const Duration(seconds: 5),
        cancelOnError: true,
      );
    } catch (e) {
      print('Error in single recognition: $e');
      completer.complete(null);
    }

    return completer.future;
  }

  void stopListening() {
    _continuousListeningTimer?.cancel();
    if (_isListening) {
      _speechToText.stop();
      _isListening = false;
    }
  }

  void pauseListening() {
    _continuousListeningTimer?.cancel();
    stopListening();
  }

  void resumeListening() {
    if (_isInitialized && !_isListening) {
      startContinuousListening();
    }
  }

  // Get available locales for speech recognition
  Future<List<LocaleName>> getAvailableLocales() async {
    return await _speechToText.locales();
  }

  // Check if specific features are supported
  Future<bool> get hasPermission => _speechToText.hasPermission;
  bool get isAvailable => _speechToText.isAvailable;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  // Get current sound level (if supported)
  double get soundLevel => _speechToText.lastStatus == 'listening' ? 1.0 : 0.0;

  void dispose() {
    _continuousListeningTimer?.cancel();
    stopListening();
    _speechController?.close();
  }
}

// Enhanced Speech Result with additional features
class EnhancedSpeechResult extends SpeechResult {
  final bool isFinal;
  final List<String> alternatives;
  final double soundLevel;
  final String locale;

  EnhancedSpeechResult({
    required String text,
    required double confidence,
    required DateTime timestamp,
    this.isFinal = true,
    this.alternatives = const [],
    this.soundLevel = 0.0,
    this.locale = 'en_US',
  }) : super(text: text, confidence: confidence, timestamp: timestamp);
}
