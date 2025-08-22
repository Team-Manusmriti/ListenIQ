// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listen_iq/screens/components/colors.dart';
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
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 30),
          _buildHeader(),
          _line(),
          _buildSettingsSection(context),
          _line(),
          _buildLanguageAndHelpSection(context),
          _line(),
        ],
      ),
    );
  }

  Widget _line() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Container(height: 1, color: Colors.grey.withOpacity(0.2)),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            // backgroundColor: grey600,
            backgroundImage: AssetImage('assets/images/profile_pic.jpeg'),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // children: [
            //   Text(
            //     "$name",
            //     style: TextStyle(
            //       color: Colors.black,
            //       fontSize: 22,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            //   Text("$email", style: TextStyle(fontSize: 14, color: grey600)),
            // ],
          ),
        ],
      ),
    );
  }

  // Widget _buildProfileOptions(BuildContext context) {
  //   return Column(
  //     children: [
  //       _buildOptionItem(
  //         icon: Icons.person_outline,
  //         label: 'Share your profile',
  //         onTap: () {
  //           Navigator.pop(context); // Close drawer first
  //           context.goNamed();
  //         },
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      children: [
        _buildOptionItem(
          icon: Icons.settings_outlined,
          label: 'Settings & Privacy',
          onTap: () {
            Navigator.pop(context); // Close drawer first
            context.goNamed(RouteConstants.profileSettings);
          },
        ),
        // _buildOptionItem(
        //   icon: Icons.insights_outlined,
        //   label: 'Your Activity',
        //   onTap: () {
        //     Navigator.pop(context); // Close drawer first
        //     if (context.canPop()) {
        //       context
        //           .goNamed(RouteConstants.profile, extra: {'fromDrawer': true});
        //     }
        //   },
        // ),
        // _buildOptionItem(
        //   icon: Icons.brightness_6_outlined,
        //   label: 'Switch Appearance',
        //   onTap: () {
        //     Navigator.pop(context); // Close drawer first
        //     // Handle theme switching
        //   },
        // ),
        _buildOptionItem(
          icon: Icons.report_problem_outlined,
          label: 'Report a problem',
          // onTap: () {
          //   Navigator.pop(context); // Close drawer first
          //   context.goNamed(RouteConstants.reportProblem);
          // },
        ),
        // _buildOptionItem(
        //   icon: Icons.privacy_tip_outlined,
        //   label: 'Feedback',
        //   onTap: () {
        //     Navigator.pop(context); // Close drawer first
        //     if (context.canPop()) {
        //       context.goNamed(RouteConstants.feedback);
        //     }
        //   },
        // ),
      ],
    );
  }

  Widget _buildLanguageAndHelpSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   "Language",
          //   style: TextStyle(
          //     fontSize: 16,
          //     color: black,
          //     fontWeight: FontWeight.normal,
          //   ),
          // ),
          // SizedBox(height: 16),
          GestureDetector(
            // onTap: () {
            //   Navigator.pop(context); // Close drawer first
            //   context.goNamed(RouteConstants.helpAndSupport);
            // },
            child: Text(
              "Help & Support",
              style: TextStyle(
                fontSize: 16,
                color: black,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        label,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 10,
    );
  }
}
