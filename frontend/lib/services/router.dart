import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:listen_iq/screens/chat/chat.dart';
import 'package:listen_iq/screens/chat/chat_home.dart';
import 'package:listen_iq/screens/history.dart' show HistoryScreen;
import 'package:listen_iq/screens/home.dart';
import 'package:listen_iq/screens/voice_assistant/voice_assistant.dart';
import 'package:listen_iq/services/router_constants.dart';
import 'package:listen_iq/services/video/video_assistant.dart';
import 'package:listen_iq/services/video/video_detection_service.dart.dart';

final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: <RouteBase>[
    GoRoute(
      path: '/home',
      name: RouteConstants.home,
      builder: (BuildContext context, GoRouterState state) {
        return HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/voiceAssistant',
          name: RouteConstants.voiceAssistant,
          builder: (BuildContext context, GoRouterState state) {
            return VoiceAssistantScreen();
          },
        ),
        GoRoute(
          path: '/chat_home',
          name: RouteConstants.chatHome,
          builder: (BuildContext context, GoRouterState state) {
            return ChatHome();
          },
          routes: <RouteBase>[
            GoRoute(
              path: '/chat',
              name: RouteConstants.chat,
              builder: (BuildContext context, GoRouterState state) {
                return ChatScreen();
              },
            ),
            GoRoute(
              path: '/videoAssistant',
              name: RouteConstants.videoAssistant,
              builder: (BuildContext context, GoRouterState state) {
                return VideoDetectionScreen();
              },
              // routes: <RouteBase>[
              //   GoRoute(
              //     path: '/upload',
              //     name: RouteConstants.videoUpload,
              //     builder: (BuildContext context, GoRouterState state) {
              //       return VideoDetectionService();
              //     },
              //   ),
              // ],
            ),

            //    GoRoute(
            //   path: '/videoAssistant',
            //   name: RouteConstants.videoAssistant,
            //   builder: (BuildContext context, GoRouterState state) {
            //     return VideoUploadingScreen();
            //   },
            // ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/history',
      name: RouteConstants.history,
      builder: (BuildContext context, GoRouterState state) {
        return HistoryScreen();
      },
    ),

    // GoRoute(
    //   path: '/settings',
    //   name: RouteConstants.settings,
    //   builder: (BuildContext context, GoRouterState state) {
    //     return SettingsScreen();
    //   },
    // ),
  ],
);
