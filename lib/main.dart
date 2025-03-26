import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';

import 'auth/login_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'utils/theme_provider.dart';
import 'utils/localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window settings for desktop
  await windowManager.ensureInitialized();
  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.acrylic,
    color: Colors.transparent,
  );

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: "SAGE Scripts Platform",
    minimumSize: Size(800, 600),
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        Provider(create: (_) => DatabaseService()),
        ChangeNotifierProxyProvider<DatabaseService, AuthService>(
          create: (context) => AuthService(
            Provider.of<DatabaseService>(context, listen: false),
          ),
          update: (context, database, previous) =>
              previous ?? AuthService(database),
        ),
      ],
      child: const CollaborativeScriptsApp(),
    ),
  );
}

class CollaborativeScriptsApp extends StatelessWidget {
  const CollaborativeScriptsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return MaterialApp(
      title: localizationProvider.getText('title'),
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      home: const LoginScreen(),
      onGenerateRoute: (settings) {
        // Esto permite controlar las transiciones de navegación
        // Pero mantenemos la navegación simple por ahora
        return null;
      },
    );
  }
}

// Extensión de NavigatorState para facilitar navegación con transiciones personalizadas
extension NavigatorExtension on NavigatorState {
  Future<T?> pushSlide<T>(Widget page) {
    return push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<T?> pushFade<T>(Widget page) {
    return push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
