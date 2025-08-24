import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:listen_iq/screens/components/colors.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'package:listen_iq/screens/components/sidemenu.dart';
import 'package:listen_iq/services/router_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> with TickerProviderStateMixin {
  AnimationController? _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _waveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: transparent,
      // backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        children: [
          // Gradient Blobs
          Positioned(
            top: -100,
            left: -80,
            child: _buildBlob(const [
              Color(0xFFd4145a),
              Color(0xFFfbb03b),
            ], 300),
          ),
          // Positioned(
          //   top: 200,
          //   right: -100,
          //   child: _buildBlob(const [
          //     Color(0xFF662d8c),
          //     Color(0xFFd4145a),
          //   ], 250),
          // ),
          // Positioned(
          //   bottom: -120,
          //   left: 50,
          //   child: _buildBlob(const [
          //     Color(0xFFfbb03b),
          //     Color(0xFF662d8c),
          //   ], 280),
          // ),

          // Blur Layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 150, sigmaY: 150),
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),

          // Wave Transition behind app bar
          if (_waveController != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _waveController!,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animationValue: _waveController!.value,
                      gradientColors: [
                        const Color(0xFFd4145a).withOpacity(0.3),
                        const Color(0xFF662d8c).withOpacity(0.4),
                        const Color(0xFFfbb03b).withOpacity(0.2),
                      ],
                    ),
                    size: Size(MediaQuery.of(context).size.width, 200),
                  );
                },
              ),
            ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Open side menu
                          // Scaffold.of(context).openDrawer();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFd4145a),
                                Color(0xFF662d8c),
                                Color(0xFFfbb03b),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          "ListenIQ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Hero Text
                  const Text(
                    'Create, explore,\nbe inspired',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Search Bar
                  GestureDetector(
                    onTap: () {
                      // Handle search tap
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Search...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              context.goNamed(RouteConstants.voiceAssistant);
                            },
                            child: const Icon(
                              Icons.mic,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // AI Tools Grid
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildAIToolCard(
                          'AI text\nwriter',
                          Icons.edit_outlined,
                        ),
                        const SizedBox(width: 12),
                        _buildAIToolCard(
                          'AI image\ngenerator',
                          Icons.image_outlined,
                        ),
                        const SizedBox(width: 12),
                        _buildAIToolCard(
                          'AI\ngenerator',
                          Icons.auto_awesome_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // History Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Handle see all tap
                        },
                        child: Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // History Items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildHistoryItem(
                          'Code tutor',
                          'How to use Visual Studio',
                          Icons.code,
                          const Color(0xFFEC4899),
                        ),
                        _buildHistoryItem(
                          'Text writer',
                          'Healthy eating tips',
                          Icons.edit,
                          const Color(0xFF8B5CF6),
                        ),
                        _buildHistoryItem(
                          'Image generator',
                          'Dog in red plaid in house in winter',
                          Icons.image,
                          const Color(0xFFF59E0B),
                        ),
                        _buildHistoryItem(
                          'Text writer',
                          'Best clothing combinations',
                          Icons.edit,
                          const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(List<Color> colors, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
          center: Alignment.center,
          radius: 0.7,
        ),
      ),
    );
  }

  Widget _buildAIToolCard(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Handle tool card tap
      },
      child: Container(
        width: 120,
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text at the top
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            // Spacer to push arrow to bottom
            const Spacer(),
            // Arrow at bottom right
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.arrow_outward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: () {
        // Handle history item tap
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final List<Color> gradientColors;

  WavePainter({required this.animationValue, required this.gradientColors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from top left
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.6);

    // Create multiple wave layers
    for (int i = 0; i < 1; i++) {
      // waveHeight = changes the height of the wave
      final waveHeight = 20 + (i * 20);

      // frequency = changes the speed of the wave
      final frequency = 0.02 + (i * 0.01);

      // phaseShift = changes the starting position of the wave
      final phaseShift = animationValue * 2 * math.pi + (i * math.pi / 3);

      for (double x = 0; x <= size.width; x += 1) {
        final y =
            size.height * 0.6 +
            waveHeight * math.sin((x * frequency) + phaseShift) +
            (waveHeight / 2) * math.cos((x * frequency * 2) + phaseShift);
        // size.height = changes the vertical position of the wave
        // math.sin = changes the wave's shape
        // math.cos = changes the wave's shape

        if (x == 0) {
          path.lineTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    // Close the path
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Add a second layer for depth
    // final path2 = Path();
    // path2.moveTo(0, 0);
    // path2.lineTo(0, size.height * 0.4);

    // for (double x = 0; x <= size.width; x += 2) {
    //   final y =
    //       size.height * 0.4 +
    //       15 *
    //           math.sin((x * 0.015) + (animationValue * 2 * math.pi) + math.pi) +
    //       8 * math.cos((x * 0.03) + (animationValue * 2 * math.pi));
    //   path2.lineTo(x, y);
    // }

    // path2.lineTo(size.width, 0);
    // path2.close();

    // final paint2 = Paint()
    //   ..shader = LinearGradient(
    //     begin: Alignment.topCenter,
    //     end: Alignment.bottomCenter,
    //     colors: gradientColors.map((c) => c.withOpacity(0.5)).toList(),
    //   ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
    //   ..style = PaintingStyle.fill;

    // canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
