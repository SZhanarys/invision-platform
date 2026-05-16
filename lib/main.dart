import 'package:flutter/material.dart';

import 'core/theme/app_theme_controller.dart';
import 'presentation/screens/auth_screen.dart';

void main() {
  runApp(const InvisionApp());
}

class InvisionApp extends StatelessWidget {
  const InvisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Платформа Invision',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.cyan,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const AuthScreen(),
        );
      },
    );
  }
}
