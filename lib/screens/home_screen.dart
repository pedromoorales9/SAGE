import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import '../services/auth_service.dart';
import '../utils/localization.dart';
import '../utils/theme_provider.dart';
import '../utils/responsive.dart';
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
  bool _isExtendedRail = true;

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
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

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
            if (isDesktop || isTablet) {
              setState(() {
                _isExtendedRail = !_isExtendedRail;
              });
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
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
                    SizedBox(width: themeProvider.spacingSmall),
                    Text('Nuevo Script'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    const Icon(Icons.folder_open, size: 18),
                    SizedBox(width: themeProvider.spacingSmall),
                    Text('Abrir Script'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    const Icon(Icons.save, size: 18),
                    SizedBox(width: themeProvider.spacingSmall),
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
                    SizedBox(width: themeProvider.spacingSmall),
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
                    SizedBox(width: themeProvider.spacingSmall),
                    const Text('Cortar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    const Icon(Icons.content_copy, size: 18),
                    SizedBox(width: themeProvider.spacingSmall),
                    const Text('Copiar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'paste',
                child: Row(
                  children: [
                    const Icon(Icons.content_paste, size: 18),
                    SizedBox(width: themeProvider.spacingSmall),
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
      drawer: !isDesktop && !isTablet
          ? _buildDrawer(tabs, themeProvider, localization, authService)
          : null,
      body: Row(
        children: [
          // NavigationRail para tablets y desktops
          if (isDesktop || isTablet)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isExtendedRail ? 200 : 80,
              child: NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() => _currentIndex = index);
                },
                labelType: _isExtendedRail
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.selected,
                extended: _isExtendedRail,
                backgroundColor: themeProvider.cardBackground(context),
                selectedIconTheme: IconThemeData(
                  color: themeProvider.primaryButtonColor(context),
                ),
                unselectedIconTheme: IconThemeData(
                  color: themeProvider.secondaryTextColor(context),
                ),
                selectedLabelTextStyle: TextStyle(
                  color: themeProvider.primaryButtonColor(context),
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: themeProvider.secondaryTextColor(context),
                ),
                destinations: tabs
                    .map((tab) => NavigationRailDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.icon),
                          label: Text(tab.title),
                        ))
                    .toList(),
                // Añade footer con botón de logout
                trailing: _isExtendedRail
                    ? Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(
                                bottom: themeProvider.spacingLarge),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                      )
                    : null,
              ),
            ),

          // Contenido principal
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: tabs.map((tab) => tab.screen).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? BottomNavigationBar(
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
              elevation: 8,
            )
          : null,
    );
  }

  Widget _buildDrawer(List<_TabItem> tabs, ThemeProvider themeProvider,
      LocalizationProvider localization, AuthService authService) {
    return Drawer(
      backgroundColor: themeProvider.cardBackground(context),
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
                SizedBox(height: themeProvider.spacingSmall),
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
          const Divider(),
          // Apartado de configuración en el drawer
          ExpansionTile(
            leading: const Icon(Icons.settings),
            title: Text('Configuración'),
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(localization.getText('language')),
                onTap: () {
                  Provider.of<LocalizationProvider>(context, listen: false)
                      .toggleLocale();
                },
              ),
              ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                title: Text(localization.getText('theme')),
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
              ),
            ],
          ),
        ],
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
