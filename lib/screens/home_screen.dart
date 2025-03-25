import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import '../services/auth_service.dart';
import '../utils/localization.dart';
import '../utils/theme_provider.dart';
import '../auth/login_screen.dart';
import 'scripts_screen.dart';
import 'admin_screen.dart';
import 'history_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Confirmar salida'),
            content: const Text('¿Seguro que desea salir?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await windowManager.destroy();
                },
                child: const Text('Salir'),
              ),
            ],
          );
        },
      );
    }
  }

  void _logout() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.logout();

    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);

    final isAdmin = authService.isAdmin;

    // Determine available tabs
    final tabs = [
      // Scripts tab - always available
      _TabItem(
        index: 0,
        title: localization.getText('scripts'),
        icon: Icons.code,
        screen: const ScriptsScreen(),
      ),
      // Chatbot tab - always available
      _TabItem(
        index: 1,
        title: localization.getText('chatbot_title'),
        icon: Icons.chat,
        screen: const ChatbotScreen(),
      ),
      // Admin tab - only available for admin users
      if (isAdmin)
        _TabItem(
          index: 2,
          title: localization.getText('admin'),
          icon: Icons.admin_panel_settings,
          screen: const AdminScreen(),
        ),
      // History tab - always available
      _TabItem(
        index: isAdmin ? 3 : 2,
        title: localization.getText('history'),
        icon: Icons.history,
        screen: const HistoryScreen(),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          localization.getText('title'),
          style: TextStyle(
            color: themeProvider.textColor(context),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          // Menú de Archivo
          PopupMenuButton<String>(
            tooltip: 'Archivo',
            icon: const Icon(Icons.file_present),
            onSelected: (value) {
              switch (value) {
                case 'new':
                  // Crear nuevo script
                  break;
                case 'open':
                  // Abrir script
                  break;
                case 'save':
                  // Guardar script
                  break;
                case 'exit':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 18),
                    const SizedBox(width: 8),
                    Text('Nuevo Script'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    const Icon(Icons.folder_open, size: 18),
                    const SizedBox(width: 8),
                    Text('Abrir Script'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    const Icon(Icons.save, size: 18),
                    const SizedBox(width: 8),
                    Text('Guardar Script'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'exit',
                child: Row(
                  children: [
                    const Icon(Icons.exit_to_app, size: 18),
                    const SizedBox(width: 8),
                    Text('Salir'),
                  ],
                ),
              ),
            ],
          ),

          // Menú Editar
          PopupMenuButton<String>(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit),
            onSelected: (value) {
              // Implementar acciones del menú editar
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cut',
                child: Row(
                  children: [
                    const Icon(Icons.content_cut, size: 18),
                    const SizedBox(width: 8),
                    const Text('Cortar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    const Icon(Icons.content_copy, size: 18),
                    const SizedBox(width: 8),
                    const Text('Copiar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'paste',
                child: Row(
                  children: [
                    const Icon(Icons.content_paste, size: 18),
                    const SizedBox(width: 8),
                    const Text('Pegar'),
                  ],
                ),
              ),
            ],
          ),

          // Botones originales
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: '${localization.getText('language')} (Alt+L)',
            onPressed: () {
              Provider.of<LocalizationProvider>(context, listen: false)
                  .toggleLocale();
            },
          ),
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: '${localization.getText('theme')} (Alt+T)',
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '${localization.getText('logout')} (Alt+Q)',
            onPressed: _logout,
          ),

          // Botones de control de ventana en Windows/Linux
          if (Platform.isWindows || Platform.isLinux) ...[
            IconButton(
              icon: const Icon(Icons.minimize, size: 18),
              tooltip: 'Minimizar',
              onPressed: () {
                windowManager.minimize();
              },
            ),
            IconButton(
              icon: const Icon(Icons.crop_square, size: 18),
              tooltip: 'Maximizar',
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Cerrar',
              onPressed: () {
                windowManager.close();
              },
            ),
          ],
        ],
        backgroundColor: themeProvider.appBarBackground(context),
        elevation: 0,
        // Make the window draggable from the AppBar (Windows desktop feature)
        toolbarHeight: 50,
        flexibleSpace: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            windowManager.startDragging();
          },
          onDoubleTap: () async {
            bool isMaximized = await windowManager.isMaximized();
            if (isMaximized) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          child: Container(
            color: Colors.transparent,
            height: 50,
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: themeProvider.cardBackground(context),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: themeProvider.primaryButtonColor(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      authService.currentUser?.username ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      authService.isAdmin
                          ? localization.getText('admin')
                          : 'Usuario',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ...tabs.map((tab) => ListTile(
                    leading: Icon(
                      tab.icon,
                      color: _currentIndex == tab.index
                          ? themeProvider.primaryButtonColor(context)
                          : null,
                    ),
                    title: Text(
                      tab.title,
                      style: TextStyle(
                        color: _currentIndex == tab.index
                            ? themeProvider.primaryButtonColor(context)
                            : null,
                        fontWeight:
                            _currentIndex == tab.index ? FontWeight.bold : null,
                      ),
                    ),
                    onTap: () {
                      setState(() => _currentIndex = tab.index);
                      Navigator.pop(context); // Close drawer
                    },
                  )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(localization.getText('logout')),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs.map((tab) => tab.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: themeProvider.cardBackground(context),
        selectedItemColor: themeProvider.primaryButtonColor(context),
        unselectedItemColor: themeProvider.secondaryTextColor(context),
        items: tabs
            .map((tab) => BottomNavigationBarItem(
                  icon: Icon(tab.icon),
                  label: tab.title,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final int index;
  final String title;
  final IconData icon;
  final Widget screen;

  _TabItem({
    required this.index,
    required this.title,
    required this.icon,
    required this.screen,
  });
}
