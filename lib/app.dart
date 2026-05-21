import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/connections/connection_form_screen.dart';
import 'features/connections/connections_screen.dart';
import 'features/session/session_screen.dart';
import 'features/settings/settings_screen.dart';

class MindbApp extends ConsumerWidget {
  const MindbApp({super.key});

  static const background = Color(0xFF0D0D0D);
  static const accent = Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ConnectionsScreen(),
        ),
        GoRoute(
          path: '/connections/new',
          builder: (context, state) => const ConnectionFormScreen(),
        ),
        GoRoute(
          path: '/connections/:id/edit',
          builder: (context, state) {
            return ConnectionFormScreen(connectionId: state.pathParameters['id']);
          },
        ),
        GoRoute(
          path: '/session/:id',
          builder: (context, state) {
            return SessionScreen(connectionId: state.pathParameters['id']!);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    final mono = GoogleFonts.jetBrainsMonoTextTheme(
      ThemeData.dark().textTheme,
    );

    return MaterialApp.router(
      title: 'mindb',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          surface: background,
          primary: accent,
          secondary: accent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: background,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: UnderlineInputBorder(),
        ),
        textTheme: mono,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
