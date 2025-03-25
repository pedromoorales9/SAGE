import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../utils/localization.dart';
import '../utils/theme_provider.dart';
import '../screens/home_screen.dart';
import 'register_screen.dart';
import '../widgets/apple_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  
  String? _usernameError;
  String? _passwordError;
  bool _isLoading = false;
  bool _isTotpDialogOpen = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  void _validateUsername(String value) {
    setState(() {
      if (value.length < 3) {
        _usernameError = Provider.of<LocalizationProvider>(context, listen: false)
            .getText('min_chars_user');
      } else {
        _usernameError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.length < 6) {
        _passwordError = Provider.of<LocalizationProvider>(context, listen: false)
            .getText('min_chars_pass');
      } else {
        _passwordError = null;
      }
    });
  }

  Future<void> _login() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    // Validate inputs
    _validateUsername(_usernameController.text);
    _validatePassword(_passwordController.text);
    
    if (_usernameError != null || _passwordError != null) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    // Show TOTP dialog
    final totpCode = await _showTotpDialog();
    if (totpCode == null || totpCode.isEmpty) {
      setState(() => _isLoading = false);
      if (!_isTotpDialogOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('totp_required')))
        );
      }
      return;
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.login(
      _usernameController.text,
      _passwordController.text,
      totpCode,
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen())
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText(result['message'])))
      );
    }
  }
  
  Future<String?> _showTotpDialog() async {
    _isTotpDialogOpen = true;
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localization.getText('totp_code')),
        content: TextField(
          controller: _totpController,
          decoration: InputDecoration(
            hintText: localization.getText('enter_code'),
            filled: true,
            fillColor: themeProvider.inputBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(localization.getText('back')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_totpController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryButtonColor(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(localization.getText('login')),
          ),
        ],
      ),
    );
    
    _isTotpDialogOpen = false;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeProvider.scaffoldBackground(context),
                  themeProvider.cardBackground(context),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: themeProvider.primaryButtonColor(context),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.code,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // App Title
                    Text(
                      localization.getText('title'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    // Login Card
                    Container(
                      width: 400,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeProvider.cardBackground(context),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.getText('login'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textColor(context),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Username Field
                          Text(
                            localization.getText('username'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: themeProvider.secondaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            onChanged: _validateUsername,
                            decoration: InputDecoration(
                              hintText: localization.getText('username'),
                              errorText: _usernameError,
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: themeProvider.inputBackground(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field
                          Text(
                            localization.getText('password'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: themeProvider.secondaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            onChanged: _validatePassword,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: localization.getText('password'),
                              errorText: _passwordError,
                              prefixIcon: const Icon(Icons.lock),
                              filled: true,
                              fillColor: themeProvider.inputBackground(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Login Button
                          AppleButton(
                            onPressed: _isLoading ? null : _login,
                            label: localization.getText('login'),
                            isLoading: _isLoading,
                            isPrimary: true,
                          ),
                          const SizedBox(height: 16),
                          
                          // Register Button
                          AppleButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen())
                              );
                            },
                            label: localization.getText('register'),
                            isPrimary: false,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Language Toggle
                        TextButton.icon(
                          onPressed: () {
                            Provider.of<LocalizationProvider>(context, listen: false).toggleLocale();
                          },
                          icon: const Icon(Icons.language),
                          label: Text(localization.getText('language')),
                        ),
                        const SizedBox(width: 10),
                        
                        // Theme Toggle
                        TextButton.icon(
                          onPressed: () {
                            Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                          },
                          icon: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                          ),
                          label: Text(localization.getText('theme')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Credits
                    Text(
                      localization.getText('created_by'),
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.secondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}