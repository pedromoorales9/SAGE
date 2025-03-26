import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Sistema de Diseño Unificado - Espaciados
  double get spacingTiny => 4.0;
  double get spacingSmall => 8.0;
  double get spacingMedium => 16.0;
  double get spacingLarge => 24.0;
  double get spacingXLarge => 32.0;

  // Sistema de Diseño Unificado - Bordes redondeados
  double get borderRadiusSmall => 8.0;
  double get borderRadiusMedium => 12.0;
  double get borderRadiusLarge => 16.0;
  double get borderRadiusXLarge => 24.0;

  // Helper methods for consistent colors based on theme
  Color cardBackground(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  Color cardElevation(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.1);
  }

  Color appBarBackground(BuildContext context) {
    return Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).primaryColor;
  }

  Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color inputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF323234)
        : const Color(0xFFF2F2F7);
  }

  Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Color secondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
  }

  Color dividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.black12;
  }

  Color primaryButtonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0A84FF)
        : const Color(0xFF007AFF);
  }

  Color secondaryButtonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);
  }

  // Success, warning, error colors for feedback
  Color successColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF30D158)
        : const Color(0xFF34C759);
  }

  Color warningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFD60A)
        : const Color(0xFFFF9500);
  }

  Color errorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF453A)
        : const Color(0xFFFF3B30);
  }

  // Code editor theme colors
  Color editorBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF9F9F9);
  }

  Color editorText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF000000);
  }

  Color editorKeyword(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF5555)
        : const Color(0xFFAF0000);
  }

  Color editorComment(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7D7D7D)
        : const Color(0xFF8E908C);
  }

  Color editorString(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF87D37C)
        : const Color(0xFF008000);
  }

  Color editorNumber(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFBD93F9)
        : const Color(0xFF7159C1);
  }

  // Temas completos - Light y Dark
  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF007AFF),
        canvasColor: const Color(0xFFF2F2F7),
        cardColor: Colors.white,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Colors.white,
          selectedIconTheme: IconThemeData(color: Color(0xFF007AFF)),
          selectedLabelTextStyle: TextStyle(color: Color(0xFF007AFF)),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.white,
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE5E5EA),
          disabledColor: const Color(0xFFE5E5EA).withOpacity(0.5),
          selectedColor: const Color(0xFF007AFF),
          secondarySelectedColor: const Color(0xFF007AFF),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          labelStyle: const TextStyle(color: Colors.black87),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          brightness: Brightness.light,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF0A84FF),
        canvasColor: const Color(0xFF1C1C1E),
        cardColor: const Color(0xFF2C2C2E),
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C2C2E),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF2C2C2E),
          selectedIconTheme: IconThemeData(color: Color(0xFF0A84FF)),
          selectedLabelTextStyle: TextStyle(color: Color(0xFF0A84FF)),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF3A3A3C),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: const Color(0xFF2C2C2E),
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF3A3A3C),
          disabledColor: const Color(0xFF3A3A3C).withOpacity(0.5),
          selectedColor: const Color(0xFF0A84FF),
          secondarySelectedColor: const Color(0xFF0A84FF),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          labelStyle: const TextStyle(color: Colors.white),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          brightness: Brightness.dark,
        ),
      );
}
