import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import 'package:listen_iq/screens/components/sidemenu.dart';
import 'package:listen_iq/services/router_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
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
          Positioned(
            top: 200,
            right: -100,
            child: _buildBlob(const [
              Color(0xFF662d8c),
              Color(0xFFd4145a),
            ], 250),
          ),
          Positioned(
            bottom: -120,
            left: 50,
            child: _buildBlob(const [
              Color(0xFFfbb03b),
              Color(0xFF662d8c),
            ], 280),
          ),

          // Blur Layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 150, sigmaY: 150),
            child: Container(color: Colors.black.withOpacity(0.25)),
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.purple, Colors.red],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => SideMenu(),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {},
                        child: const Text("ListenIQ"),
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
                  Container(
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
                        Icon(Icons.search, color: Colors.white70, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Search...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () {
                            context.goNamed(RouteConstants.voiceAssistant);
                          },
                          child: Icon(
                            Icons.mic,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
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
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
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
    return Container(
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
    );
  }

  Widget _buildHistoryItem(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
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
    );
  }
}
