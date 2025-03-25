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
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
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
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
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
        // Eliminada la referencia a fontFamily
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
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
        // Eliminada la referencia a fontFamily
      ),
      home: const LoginScreen(),
    );
  }
}