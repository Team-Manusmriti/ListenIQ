// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listen_iq/services/router_constants.dart';

class SideMenu extends ConsumerStatefulWidget {
  const SideMenu({super.key});

  @override
  ConsumerState<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends ConsumerState<SideMenu> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      width: MediaQuery.of(context).size.width * 0.7,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildServicesSection(context),
          const SizedBox(height: 24),
          _buildSettingsSection(context),
          const SizedBox(height: 24),
          _buildSupportSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Menu",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Choose a service",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Services"),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.videocam,
          label: 'Video',
          color: const Color(0xFFEC4899),
          onTap: () {
            Navigator.of(context).pop();
            // Navigate to video service
          },
        ),
        _buildMenuItem(
          icon: Icons.screen_share,
          label: 'Screen Recording',
          color: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.of(context).pop();
            // Navigate to screen recording service
          },
        ),
        _buildMenuItem(
          icon: Icons.audiotrack,
          label: 'Audio',
          color: const Color(0xFFF59E0B),
          onTap: () {
            Navigator.of(context).pop();
            // Navigate to audio service
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Settings"),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.settings,
          label: 'Settings & Privacy',
          onTap: () {
            Navigator.of(context).pop();
            context.goNamed(RouteConstants.profileSettings);
          },
        ),
        _buildMenuItem(
          icon: Icons.report_problem,
          label: 'Report a problem',
          onTap: () {
            Navigator.of(context).pop();
            // Handle report problem
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Support"),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.help,
          label: 'Help & Support',
          onTap: () {
            Navigator.of(context).pop();
            // Navigate to help & support
          },
        ),
        _buildMenuItem(
          icon: Icons.language,
          label: 'Language',
          onTap: () {
            Navigator.of(context).pop();
            // Handle language selection
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color ?? Colors.white.withOpacity(0.8),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
