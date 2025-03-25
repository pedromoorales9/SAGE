import 'package:flutter/material.dart';
import 'package:otp/otp.dart';

import '../models/user_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final DatabaseService _database;
  
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  
  AuthService(this._database);
  
  Future<Map<String, dynamic>> login(String username, String password, String totpCode) async {
    try {
      // Verify username and password
      final passwordValid = await _database.verifyPassword(username, password);
      if (!passwordValid) {
        return {
          'success': false,
          'message': 'invalid_credentials',
        };
      }
      
      // Get user data
      final user = await _database.getUserByUsername(username);
      if (user == null) {
        return {
          'success': false,
          'message': 'invalid_credentials',
        };
      }
      
      // Check if user is approved
      if (!user.approved) {
        return {
          'success': false,
          'message': 'pending_approval',
        };
      }
      
      // Verify TOTP code
      if (!verifyTOTP(user.totpSecret!, totpCode)) {
        return {
          'success': false,
          'message': 'totp_invalid',
        };
      }
      
      // Set current user and notify listeners
      _currentUser = user;
      notifyListeners();
      
      return {
        'success': true,
        'user': user,
      };
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'error',
        'error': e.toString(),
      };
    }
  }
  
  Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      if (username.length < 3 || password.length < 6) {
        return {
          'success': false,
          'message': 'complete_fields',
        };
      }
      
      // Check if username already exists
      final existingUser = await _database.getUserByUsername(username);
      if (existingUser != null) {
        return {
          'success': false,
          'message': 'username_taken',
        };
      }
      
      // Create new user
      final totpSecret = await _database.createUser(username, password);
      if (totpSecret == null) {
        return {
          'success': false,
          'message': 'error',
          'error': 'Failed to create user',
        };
      }
      
      return {
        'success': true,
        'totpSecret': totpSecret,
      };
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'error',
        'error': e.toString(),
      };
    }
  }
  
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
  
  bool verifyTOTP(String secret, String code) {
    if (code.isEmpty) return false;
    
    // Remove any spaces or hyphens from the code
    code = code.replaceAll(RegExp(r'[^0-9]'), '');
    
    try {
      // Get current TOTP value
      final currentCode = OTP.generateTOTPCodeString(
        secret, 
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      
      return code == currentCode;
    } catch (e) {
      print('TOTP verification error: $e');
      return false;
    }
  }
  
  String generateTotpUri(String username, String secret) {
    return 'otpauth://totp/SAGE:$username?secret=$secret&issuer=SAGE';
  }
}