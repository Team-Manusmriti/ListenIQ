import 'dart:async';
import 'dart:math' as math;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:listen_iq/screens/components/voice_assistant/audio_assistant.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _statusController;
  late AnimationController _meshController;
  late AnimationController _textController;

  double _level = 0.0;
  final _service = AudioIntensityService();
  bool _running = false;
  StreamSubscription<double>? _levelSubscription;
  String _status =
      "Tell me about this year's top 5 trends for Instagram marketers";

  // Speech-to-text functionality
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _recognizedText = '';
  List<String> _words = [];
  String _lastFullText = '';
  String _lastWords = '';

  // Color scheme as specified
  static const Color primaryPurple = Color(0xFF662d8c);
  static const Color accentPink = Color(0xFFd4145a);
  static const Color accentYellow = Color(0xFFfbb03b);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupAudioListener();
    _initializeSpeech();
  }

  void _initializeAnimations() {
    try {
      _waveController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3500),
      );

      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );

      _particleController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 10000),
      );

      _statusController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );

      _meshController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 16000),
      );

      _textController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );

      // Start continuous animations
      _waveController.repeat();
      _particleController.repeat();
      _meshController.repeat();
    } catch (e) {
      print('Error initializing animations: $e');
    }
  }

  void _setupAudioListener() {
    try {
      _levelSubscription = _service.levelStream
          .distinct((a, b) => (a - b).abs() < 0.01) // ignore tiny changes
          .listen(
            (v) {
              if (mounted) setState(() => _level = v);
            },
            onError: (error) {
              print('Error in audio stream: $error');
              if (mounted) {
                setState(() {
                  _level = 0.0;
                  _running = false;
                  _status = "Audio error occurred";
                });
              }
            },
          );
    } catch (e) {
      print('Error setting up audio listener: $e');
    }
  }

  void _initializeSpeech() async {
    try {
      _speech = stt.SpeechToText();
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (mounted) {
            setState(() {
              _isListening = status == 'listening';
            });
          }
        },
        onError: (error) {
          print('Speech error: $error');
          if (mounted) {
            setState(() {
              _isListening = false;
              _status = "Speech recognition error";
            });
          }
        },
      );

      if (!_speechAvailable) {
        print('Speech recognition not available');
      }
    } catch (e) {
      print('Error initializing speech: $e');
      _speechAvailable = false;
    }
  }

  void _startListening() async {
    if (!_speechAvailable) return;

    try {
      setState(() {
        _recognizedText = '';
        _lastWords = '';
        _words.clear();
      });

      await _speech.listen(
        onResult: (val) {
          if (mounted) {
            setState(() {
              _recognizedText = val.recognizedWords;
              _words = val.recognizedWords.split(' ');
              _lastWords = val.recognizedWords;
              if (_recognizedText.isNotEmpty) {
                _textController.forward();
              }
              if (val.hasConfidenceRating && val.confidence > 0) {
                // Optionally handle confidence
              }
            });
          }
        },
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 30),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
          _status = "Failed to start speech recognition";
        });
      }
    }
  }

  void _stopListening() async {
    try {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  Future<void> _toggle() async {
    if (!mounted) return;

    try {
      setState(() {
        _status = _running ? "Processing..." : "Listening...";
      });

      _statusController.forward().then((_) {
        if (mounted) {
          _statusController.reverse();
        }
      });

      if (_running) {
        // Stop both audio recording and speech recognition
        await _service.stop();
        _stopListening();
        _pulseController.stop();
        _textController.reverse();

        if (mounted) {
          setState(() {
            _status =
                "Tell me about this year's top 5 trends for Instagram marketers";
            _running = false;
          });
        }
      } else {
        // Start both audio recording and speech recognition
        await _service.start();
        if (_speechAvailable) {
          _startListening();
        }
        _pulseController.repeat();

        if (mounted) {
          setState(() {
            _status = "Listening... Tap to stop";
            _running = true;
          });
        }
      }
    } catch (e) {
      print('Error toggling recording: $e');
      if (mounted) {
        setState(() {
          _status = "Error: ${e.toString()}";
          _running = false;
        });
        _pulseController.stop();
      }
    }
  }

  void _clearText() {
    setState(() {
      _recognizedText = '';
      _lastWords = '';
      _words.clear();
    });
    _textController.reverse();
  }

  @override
  void dispose() {
    try {
      _levelSubscription?.cancel();
      _service.dispose();
      _speech.stop();
      _waveController.dispose();
      _pulseController.dispose();
      _particleController.dispose();
      _statusController.dispose();
      _meshController.dispose();
      _textController.dispose();
    } catch (e) {
      print('Error disposing resources: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5 + (_level * 0.4),
            colors: [
              primaryPurple.withOpacity(0.6 + _level * 0.3),
              primaryPurple.withOpacity(0.3 + _level * 0.2),
              const Color(0xFF1a0d2e),
              Colors.black,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Spacer(flex: 2),
              _buildMainVisualization(),
              const Spacer(flex: 1),
              _buildStatusText(),
              if (_recognizedText.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildRecognizedText(),
              ],
              const Spacer(flex: 2),
              _buildBottomControls(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white70,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          AnimatedContainer(
            duration: Duration(milliseconds: _running ? 100 : 300),
            width: 32 + (_running ? _level * 4 : 0),
            height: 32 + (_running ? _level * 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: _running
                    ? [
                        Color.lerp(primaryPurple, accentPink, _level)!,
                        Color.lerp(
                          primaryPurple.withOpacity(0.8),
                          accentYellow,
                          _level * 0.5,
                        )!,
                      ]
                    : [primaryPurple, primaryPurple.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: _running && _level > 0.3
                  ? [
                      BoxShadow(
                        color: accentPink.withOpacity(_level * 0.6),
                        blurRadius: 8 + (_level * 4),
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18 + (_running ? _level * 2 : 0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Text writer",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "Marketing in 2025",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (_isListening) ...[
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentPink.withOpacity(
                                0.6 +
                                    0.4 *
                                        math.sin(
                                          _pulseController.value * 2 * math.pi,
                                        ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMainVisualization() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 320 + (_running ? _level * 80 : 0),
      transform: Matrix4.identity()
        ..scale(1.0 + (_running ? _level * 0.15 : 0)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Enhanced background glow
          if (_running && _level > 0.1)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentPink.withOpacity(_level * 0.4),
                      blurRadius: 120 + (_level * 80),
                      spreadRadius: 30 + (_level * 40),
                    ),
                    BoxShadow(
                      color: primaryPurple.withOpacity(_level * 0.3),
                      blurRadius: 80 + (_level * 60),
                      spreadRadius: 20 + (_level * 30),
                    ),
                  ],
                ),
              ),
            ),

          // Main 3D Mesh Animation
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _waveController,
                _particleController,
                _meshController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: Optimized3DMeshPainter(
                    waveTime: _waveController.value,
                    particleTime: _particleController.value,
                    meshTime: _meshController.value,
                    level: _level,
                    isActive: _running,
                  ),
                );
              },
            ),
          ),

          // Responsive outer rings
          if (_running)
            ...List.generate(
              2,
              (index) => AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final ringOpacity =
                      (_level * 0.5) *
                      (0.7 - index * 0.2) *
                      (0.5 +
                          0.5 *
                              math.sin(
                                _pulseController.value * 2 * math.pi +
                                    index * 0.5,
                              ));

                  return Container(
                    width: 180 + (index * 60) + (_level * 100),
                    height: 180 + (index * 60) + (_level * 100),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index == 0
                            ? accentPink.withOpacity(ringOpacity)
                            : accentYellow.withOpacity(ringOpacity * 0.7),
                        width: 1.5,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AnimatedBuilder(
        animation: _statusController,
        builder: (context, child) {
          return Transform.scale(
            scale:
                1.0 +
                (_statusController.value * 0.03) +
                (_running ? _level * 0.02 : 0),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: _running
                    ? Color.lerp(
                        Colors.white.withOpacity(0.9),
                        accentPink,
                        _level * 0.4,
                      )
                    : Colors.white.withOpacity(0.9),
                fontSize: 24 + (_running ? _level * 3 : 0),
                fontWeight: FontWeight.w500,
                height: 1.3,
                shadows: _running && _level > 0.3
                    ? [
                        Shadow(
                          color: accentPink.withOpacity(_level * 0.8),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(_status, textAlign: TextAlign.center),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecognizedText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _textController.value) * 20),
          child: Opacity(
            opacity: _textController.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentPink.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentPink.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        color: accentPink,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Recognized Speech",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _clearText,
                        child: Icon(
                          Icons.clear,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: _words.map((word) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            word,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildControlButton(
            icon: Icons.refresh,
            onTap: () {
              setState(() {
                _status =
                    "Tell me about this year's top 5 trends for Instagram marketers";
                _recognizedText = '';
                _lastWords = '';
              });
              _textController.reverse();
            },
          ),
          _buildMicrophoneButton(),
          _buildControlButton(
            icon: Icons.close,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white70, size: 24),
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return AvatarGlow(
      animate: _isListening,
      glowColor: Theme.of(context).primaryColor,
      duration: Duration(milliseconds: 1200),
      repeat: true,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseValue = _running ? _pulseController.value : 0.0;
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _running
                      ? [accentPink, primaryPurple]
                      : [accentPink, const Color(0xFFff8a5b)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentPink.withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 3 + (pulseValue * 10),
                  ),
                ],
              ),
              child: Icon(
                _running ? Icons.pause : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Enhanced 3D Mesh Painter for sophisticated visualization
class Optimized3DMeshPainter extends CustomPainter {
  final double waveTime;
  final double particleTime;
  final double meshTime;
  final double level;
  final bool isActive;

  // Cache paint objects (avoid recreating per frame)
  final Paint meshPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final Paint particlePaint = Paint()..style = PaintingStyle.fill;

  Optimized3DMeshPainter({
    required this.waveTime,
    required this.particleTime,
    required this.meshTime,
    required this.level,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    _draw3DMesh(canvas, size, center);

    if (isActive) {
      _drawParticles(canvas, center);
    }
  }

  void _draw3DMesh(Canvas canvas, Size size, Offset center) {
    const gridSize = 10; // reduced from 15
    const layers = 2; // reduced from 3

    for (int layer = 0; layer < layers; layer++) {
      final layerDepth = layer / layers;
      final layerScale = 0.6 + layerDepth * 0.4 + level * 0.2;
      final layerOpacity = 0.8 - layerDepth * 0.3;

      final points = <List<Offset>>[];

      for (int i = 0; i <= gridSize; i++) {
        final row = <Offset>[];
        for (int j = 0; j <= gridSize; j++) {
          final x = (i / gridSize - 0.5) * 180 * layerScale;
          final y = (j / gridSize - 0.5) * 180 * layerScale;

          final waveX =
              math.sin((i + j) * 0.3 + meshTime * 2 * math.pi) * 10 * level;
          final waveY =
              math.cos((i - j) * 0.4 + meshTime * 1.5 * math.pi) * 8 * level;
          final waveZ =
              math.sin(i * 0.2 + j * 0.3 + meshTime * math.pi) * 6 * level;

          final projectedX = center.dx + x + waveX + waveZ * 0.4;
          final projectedY = center.dy + y + waveY + waveZ * 0.25;

          row.add(Offset(projectedX, projectedY));
        }
        points.add(row);
      }

      final baseOpacity = layerOpacity * (0.4 + level * 0.6);

      // Horizontal lines
      for (int i = 0; i < points.length; i++) {
        final path = Path()..addPolygon(points[i], false);

        final hue = (meshTime * 25 + layer * 50 + i * 4) % 360;
        meshPaint.color = HSVColor.fromAHSV(
          baseOpacity,
          hue,
          0.6 + level * 0.3,
          0.8,
        ).toColor();

        canvas.drawPath(path, meshPaint);
      }

      // Vertical lines
      for (int j = 0; j <= gridSize; j++) {
        final path = Path();
        for (int i = 0; i < points.length; i++) {
          if (i == 0) {
            path.moveTo(points[i][j].dx, points[i][j].dy);
          } else {
            path.lineTo(points[i][j].dx, points[i][j].dy);
          }
        }

        final hue = (meshTime * 25 + j * 6 + layer * 50 + 120) % 360;
        meshPaint.color = HSVColor.fromAHSV(
          baseOpacity,
          hue,
          0.6 + level * 0.4,
          0.7,
        ).toColor();

        canvas.drawPath(path, meshPaint);
      }
    }
  }

  void _drawParticles(Canvas canvas, Offset center) {
    const particleCount = 12; // reduced from 20
    const trailLength = 3; // reduced from 5

    final colors = [
      const Color(0xFFd4145a), // Pink
      const Color(0xFF662d8c), // Purple
      const Color(0xFFfbb03b), // Yellow
    ];

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi + particleTime * math.pi;
      final distance =
          70 + math.sin(particleTime * 2 * math.pi + i) * 30 * level;

      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      final particleOpacity = (0.3 + level * 0.5);

      particlePaint.color = colors[i % 3].withOpacity(particleOpacity);
      canvas.drawCircle(Offset(x, y), 2 + level * 3, particlePaint);

      // Shorter trail
      for (int t = 1; t <= trailLength; t++) {
        final trailAngle = angle - (t * 0.12);
        final trailX = center.dx + math.cos(trailAngle) * distance;
        final trailY = center.dy + math.sin(trailAngle) * distance;

        particlePaint.color = colors[i % 3].withOpacity(
          particleOpacity * (1 - t / trailLength),
        );
        canvas.drawCircle(
          Offset(trailX, trailY),
          (2 + level * 3) * (1 - t / trailLength * 0.6),
          particlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant Optimized3DMeshPainter oldDelegate) =>
      oldDelegate.waveTime != waveTime ||
      oldDelegate.particleTime != particleTime ||
      oldDelegate.meshTime != meshTime ||
      oldDelegate.level != level ||
      oldDelegate.isActive != isActive;
}
