import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/auth_service.dart';
import '../utils/localization.dart';
import '../utils/theme_provider.dart';
import '../widgets/apple_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _usernameError;
  String? _passwordError;
  bool _isLoading = false;
  String? _qrCodeData;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
  
  Future<void> _register() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    // Validate inputs
    _validateUsername(_usernameController.text);
    _validatePassword(_passwordController.text);
    
    if (_usernameError != null || _passwordError != null) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.register(
      _usernameController.text,
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      final totpSecret = result['totpSecret'];
      final totpUri = authService.generateTotpUri(_usernameController.text, totpSecret);
      
      setState(() => _qrCodeData = totpUri);
      
      _showQrCodeDialog(totpUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText(result['message'])))
      );
    }
  }
  
  void _showQrCodeDialog(String uri) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localization.getText('totp_code')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            QrImageView(
              data: uri,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              localization.getText('scan_qr'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to login screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryButtonColor(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(localization.getText('back')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.getText('register')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: themeProvider.textColor(context),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Registration Card
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
                        localization.getText('register'),
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
                      
                      // Register Button
                      AppleButton(
                        onPressed: _isLoading ? null : _register,
                        label: localization.getText('register'),
                        isLoading: _isLoading,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      
                      // Back Button
                      AppleButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        label: localization.getText('back'),
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}