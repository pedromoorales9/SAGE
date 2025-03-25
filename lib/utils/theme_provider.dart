import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    notifyListeners();
  }
  
  // Helper methods for consistent colors based on theme
  Color cardBackground(BuildContext context) {
    return Theme.of(context).cardColor;
  }
  
  Color appBarBackground(BuildContext context) {
    return Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor;
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
}