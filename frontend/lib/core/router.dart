import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_app.dart';

/// App Router Configuration
/// 
/// This class defines the routing configuration for the application using [GoRouter].
/// It matches the routes from the original React Router configuration.
class AppRouter {
  /// The global router instance.
  /// 
  /// Defines:
  /// - `initialLocation`: The starting route ('/').
  /// - `routes`: A list of [GoRoute]s, currently defining the home route.
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainApp(),
      ),
      // Additional routes can be added here for deep linking
      // GoRoute(
      //   path: '/llm-advice',
      //   name: 'llm-advice',
      //   builder: (context, state) => const LLMAdvicePage(),
      // ),
    ],
  );
}
