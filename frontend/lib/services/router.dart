import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:listen_iq/screens/home.dart';
import 'package:listen_iq/services/router_constants.dart';

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
        // GoRoute(
        //   path: '/chat',
        //   name: RouteConstants.chat,
        //   builder: (BuildContext context, GoRouterState state) {
        //     return ChatScreen();
        //   },
        // ),
        // GoRoute(
        //   path: '/tools',
        //   name: RouteConstants.tools,
        //   builder: (BuildContext context, GoRouterState state) {
        //     return ToolsScreen();
        //   },
        // ),
        // GoRoute(
        //   path: '/logs',
        //   name: RouteConstants.logs,
        //   builder: (BuildContext context, GoRouterState state) {
        //     return LogsScreen();
        //   },
        // ),
        // GoRoute(
        //   path: '/scriptGenerator',
        //   name: RouteConstants.scriptGenerator,
        //   builder: (BuildContext context, GoRouterState state) {
        //     return ScriptGeneratorScreen();
        //   },
        // ),
      ],
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
