import 'package:flutter/material.dart';

import '../theme/app_theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? 'Включить светлую тему' : 'Включить тёмную тему',
          onPressed: AppThemeController.toggleTheme,
          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
        );
      },
    );
  }
}
