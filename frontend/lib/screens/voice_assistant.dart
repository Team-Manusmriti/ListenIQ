import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:listen_iq/screens/components/voice_assistant/audio_assistant.dart';

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

  double _level = 0.0;
  final _service = AudioIntensityService();
  bool _running = false;
  StreamSubscription<double>? _levelSubscription;
  String _status =
      "Tell me about this year's top 5 trends for Instagram marketers";

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupAudioListener();
  }

  void _initializeAnimations() {
    try {
      // Wave animation for the flowing particles
      _waveController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 4000),
      );

      // Pulse animation for mic button
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );

      // Particle flow animation
      _particleController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 6000),
      );

      // Status text animation
      _statusController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );

      // Start continuous animations
      _waveController.repeat();
      _particleController.repeat();
    } catch (e) {
      print('Error initializing animations: $e');
    }
  }

  void _setupAudioListener() {
    try {
      _levelSubscription = _service.levelStream.listen(
        (v) {
          if (mounted) {
            setState(() => _level = v);
          }
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
        await _service.stop();
        _pulseController.stop();
        if (mounted) {
          setState(() {
            _status =
                "Tell me about this year's top 5 trends for Instagram marketers";
            _running = false;
          });
        }
      } else {
        await _service.start();
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

  @override
  void dispose() {
    try {
      _levelSubscription?.cancel();
      _service.dispose();
      _waveController.dispose();
      _pulseController.dispose();
      _particleController.dispose();
      _statusController.dispose();
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
            radius: 1.2 + (_level * 0.3),
            colors: [
              Color.lerp(
                const Color(0xFF2d1b69),
                const Color(0xFF4c2a85),
                _level,
              )!,
              Color.lerp(
                const Color(0xFF16213e),
                const Color(0xFF2d1b69),
                _level * 0.7,
              )!,
              Colors.black,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              const Spacer(flex: 2),

              // Main visualization area
              _buildMainVisualization(),

              const Spacer(flex: 1),

              // Status text
              _buildStatusText(),

              const Spacer(flex: 2),

              // Bottom controls
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
          // Back button
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

          // App icon with gradient
          AnimatedContainer(
            duration: Duration(milliseconds: _running ? 100 : 300),
            width: 32 + (_running ? _level * 4 : 0),
            height: 32 + (_running ? _level * 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: _running
                    ? [
                        Color.lerp(
                          const Color(0xFF8e2de2),
                          const Color(0xFFa855f7),
                          _level,
                        )!,
                        Color.lerp(
                          const Color(0xFF4a00e0),
                          const Color(0xFF7c3aed),
                          _level,
                        )!,
                      ]
                    : [const Color(0xFF8e2de2), const Color(0xFF4a00e0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: _running && _level > 0.3
                  ? [
                      BoxShadow(
                        color: const Color(
                          0xFF8e2de2,
                        ).withOpacity(_level * 0.6),
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

          // Title and subtitle
          const Expanded(
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
                Text(
                  "Marketing in 2025",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Menu button
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
      duration: Duration(milliseconds: 200),
      height: 320 + (_running ? _level * 60 : 0),
      transform: Matrix4.identity()..scale(1.0 + (_running ? _level * 0.1 : 0)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow effect
          if (_running && _level > 0.2)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8e2de2).withOpacity(_level * 0.3),
                      blurRadius: 100 + (_level * 50),
                      spreadRadius: 20 + (_level * 30),
                    ),
                  ],
                ),
              ),
            ),

          // Flowing particle animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _waveController,
                _particleController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: FlowingParticlesPainter(
                    waveTime: _waveController.value,
                    particleTime: _particleController.value,
                    level: _level,
                    isActive: _running,
                  ),
                );
              },
            ),
          ),

          // Responsive pulsing rings
          if (_running)
            ...List.generate(
              3,
              (index) => AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final ringOpacity =
                      (_level * 0.4) *
                      (0.8 - index * 0.2) *
                      (0.5 +
                          0.5 *
                              math.sin(
                                _pulseController.value * 2 * math.pi + index,
                              ));

                  return Container(
                    width: 120 + (index * 40) + (_level * 80),
                    height: 120 + (index * 40) + (_level * 80),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8e2de2).withOpacity(ringOpacity),
                        width: 2,
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
                (_statusController.value * 0.05) +
                (_running ? _level * 0.02 : 0),
            child: AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 300),
              style: TextStyle(
                color: _running
                    ? Color.lerp(
                        Colors.white.withOpacity(0.9),
                        const Color(0xFFa855f7),
                        _level * 0.3,
                      )
                    : Colors.white.withOpacity(0.9),
                fontSize: 24 + (_running ? _level * 2 : 0),
                fontWeight: FontWeight.w500,
                height: 1.3,
                shadows: _running && _level > 0.4
                    ? [
                        Shadow(
                          color: const Color(
                            0xFF8e2de2,
                          ).withOpacity(_level * 0.6),
                          blurRadius: 8,
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

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reset/Undo button
          _buildControlButton(
            icon: Icons.refresh,
            onTap: () {
              setState(() {
                _status =
                    "Tell me about this year's top 5 trends for Instagram marketers";
              });
            },
          ),

          // Main microphone button
          _buildMicrophoneButton(),

          // Close button
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
    return GestureDetector(
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
                    ? [const Color(0xFFff6b9d), const Color(0xFFc44569)]
                    : [const Color(0xFFff6b9d), const Color(0xFFffa500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFff6b9d).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2 + (pulseValue * 8),
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
    );
  }
}

// Custom painter for flowing particles effect
class FlowingParticlesPainter extends CustomPainter {
  final double waveTime;
  final double particleTime;
  final double level;
  final bool isActive;

  FlowingParticlesPainter({
    required this.waveTime,
    required this.particleTime,
    required this.level,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Create the main flowing shape
    _drawFlowingShape(canvas, size, center);

    // Add particle effects when active
    if (isActive) {
      _drawParticleTrails(canvas, size, center);
    }
  }

  void _drawFlowingShape(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Create multiple flowing layers
    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final radius = 60.0 + (layer * 25) + (level * 40);
      final points = <Offset>[];

      // Generate flowing shape points
      const pointCount = 80;
      for (int i = 0; i < pointCount; i++) {
        final angle = (i / pointCount) * 2 * math.pi;

        // Create flowing distortion
        final distortion1 = math.sin(angle * 3 + waveTime * 2 * math.pi) * 15;
        final distortion2 = math.sin(angle * 5 + waveTime * 1.5 * math.pi) * 8;
        final distortion3 = math.sin(angle * 7 + particleTime * math.pi) * 5;

        final currentRadius = radius + distortion1 + distortion2 + distortion3;

        final x = center.dx + math.cos(angle) * currentRadius;
        final y = center.dy + math.sin(angle) * currentRadius;

        points.add(Offset(x, y));
      }

      // Create smooth path through points
      if (points.isNotEmpty) {
        path.moveTo(points.first.dx, points.first.dy);

        for (int i = 0; i < points.length; i++) {
          final current = points[i];
          final next = points[(i + 1) % points.length];

          // Use quadratic curves for smoothness
          final controlPoint = Offset(
            (current.dx + next.dx) / 2,
            (current.dy + next.dy) / 2,
          );

          path.quadraticBezierTo(
            controlPoint.dx,
            controlPoint.dy,
            next.dx,
            next.dy,
          );
        }

        path.close();
      }

      // Set color with gradient effect
      final opacity = math.max(0.0, 0.8 - layer * 0.2);
      final hue = (waveTime * 60 + layer * 30) % 360;

      paint.color = HSVColor.fromAHSV(opacity, hue, 0.8, 0.9).toColor();

      canvas.drawPath(path, paint);
    }
  }

  void _drawParticleTrails(Canvas canvas, Size size, Offset center) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw flowing particle trails
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi + particleTime * math.pi;
      final distance = 80 + math.sin(particleTime * 2 * math.pi + i) * 30;

      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      final particleOpacity =
          (0.3 + level * 0.4) *
          (0.5 + 0.5 * math.sin(particleTime * 4 * math.pi + i));

      paint.color = const Color(0xFFff6b9d).withOpacity(particleOpacity);

      canvas.drawCircle(Offset(x, y), 2 + level * 3, paint);
    }
  }

  @override
  bool shouldRepaint(FlowingParticlesPainter oldDelegate) =>
      oldDelegate.waveTime != waveTime ||
      oldDelegate.particleTime != particleTime ||
      oldDelegate.level != level ||
      oldDelegate.isActive != isActive;
}
