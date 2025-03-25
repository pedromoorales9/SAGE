import 'package:mysql1/mysql1.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/user_model.dart';
import '../models/script_model.dart';

class DatabaseService {
  MySqlConnection? _connection;
  final ConnectionSettings _settings = ConnectionSettings(
    host: 'roundhouse.proxy.rlwy.net',
    port: 15111,
    user: 'root',
    password: 'yLGTWKFUCjGcDQiuCjWMrnObyAjHERra',
    db: 'railway',
  );
  
  Future<MySqlConnection> get connection async {
    if (_connection != null) {
      return _connection!;
    }
    
    _connection = await MySqlConnection.connect(_settings);
    await _initializeDatabase();
    return _connection!;
  }
  
  Future<void> _initializeDatabase() async {
    try {
      final conn = await connection;
      
      // Create users table if it doesn't exist
      await conn.query('''
        CREATE TABLE IF NOT EXISTS users (
          id INT AUTO_INCREMENT PRIMARY KEY,
          username VARCHAR(255) NOT NULL UNIQUE,
          password VARCHAR(255) NOT NULL,
          role ENUM('admin', 'user') DEFAULT 'user',
          approved BOOLEAN DEFAULT FALSE,
          totp_secret VARCHAR(255)
        )
      ''');
      
      // Create scripts table if it doesn't exist
      await conn.query('''
        CREATE TABLE IF NOT EXISTS scripts (
          id INT AUTO_INCREMENT PRIMARY KEY,
          filename VARCHAR(255) NOT NULL,
          content TEXT,
          upload_date DATETIME DEFAULT CURRENT_TIMESTAMP,
          uploaded_by VARCHAR(255),
          execution_count INT DEFAULT 0,
          downloads INT DEFAULT 0,
          last_execution DATETIME,
          modified_date DATETIME
        )
      ''');
      
      // Create execution_logs table if it doesn't exist
      await conn.query('''
        CREATE TABLE IF NOT EXISTS execution_logs (
          id INT AUTO_INCREMENT PRIMARY KEY,
          script_id INT,
          username VARCHAR(255),
          execution_date DATETIME,
          success BOOLEAN,
          FOREIGN KEY (script_id) REFERENCES scripts(id)
        )
      ''');
      
      // Create default admin user if not exists
      final results = await conn.query(
        'SELECT * FROM users WHERE username = ?',
        ['pedro']
      );
      
      if (results.isEmpty) {
        final hashedPassword = hashPassword('admin123');
        final totpSecret = generateRandomBase32();
        
        try {
          await conn.query('''
            INSERT INTO users (username, password, role, approved, totp_secret)
            VALUES (?, ?, ?, ?, ?)
          ''', ['pedro', hashedPassword, 'admin', 1, totpSecret]);
          
          print('Created default admin user (pedro) with TOTP secret: $totpSecret');
        } catch (e) {
          print('Error creating default admin user: $e');
        }
      }
    } catch (e) {
      print('Error initializing database: $e');
    }
  }
  
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  String generateRandomBase32() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = List.generate(16, (_) => chars[DateTime.now().microsecondsSinceEpoch % chars.length]);
    return random.join();
  }
  
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
  
  // User methods
  Future<User?> getUserByUsername(String username) async {
    final conn = await connection;
    
    try {
      final results = await conn.query(
        'SELECT * FROM users WHERE username = ?',
        [username]
      );
      
      if (results.isEmpty) {
        return null;
      }
      
      final row = results.first;
      return User(
        id: row['id'] as int? ?? 0,
        username: row['username'] as String? ?? 'unknown',
        role: row['role'] as String? ?? 'user',
        approved: (row['approved'] as int? ?? 0) == 1,
        totpSecret: row['totp_secret'] as String?,
      );
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }
  
  Future<bool> verifyPassword(String username, String password) async {
    final conn = await connection;
    final hashedPassword = hashPassword(password);
    
    try {
      final results = await conn.query(
        'SELECT * FROM users WHERE username = ? AND password = ?',
        [username, hashedPassword]
      );
      
      return results.isNotEmpty;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }
  
  Future<String?> createUser(String username, String password) async {
    final conn = await connection;
    final hashedPassword = hashPassword(password);
    final totpSecret = generateRandomBase32();
    
    try {
      await conn.query(
        'INSERT INTO users (username, password, totp_secret) VALUES (?, ?, ?)',
        [username, hashedPassword, totpSecret]
      );
      return totpSecret;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }
  
  Future<List<User>> getAllUsers({String? exceptUsername}) async {
    final conn = await connection;
    Results results;
    
    try {
      if (exceptUsername != null) {
        results = await conn.query(
          'SELECT * FROM users WHERE username != ?',
          [exceptUsername]
        );
      } else {
        results = await conn.query('SELECT * FROM users');
      }
      
      // Convierte cuidadosamente cada resultado a un objeto User
      return results.map((row) {
        print('Processing user row: $row'); // Para depuración
        
        // Asegurarse de que todos los campos existan y tengan tipos correctos
        return User(
          id: row['id'] as int? ?? 0,
          username: row['username'] as String? ?? 'unknown',
          role: row['role'] as String? ?? 'user',
          approved: (row['approved'] as int? ?? 0) == 1,
          totpSecret: row['totp_secret'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      // Devolver una lista vacía en caso de error para no bloquear la aplicación
      return [];
    }
  }
  
  Future<bool> approveUser(String username) async {
    final conn = await connection;
    try {
      final result = await conn.query(
        'UPDATE users SET approved = TRUE WHERE username = ?',
        [username]
      );
      
      return result.affectedRows! > 0;
    } catch (e) {
      print('Error approving user: $e');
      return false;
    }
  }
  
  Future<bool> deleteUser(String username) async {
    final conn = await connection;
    try {
      final result = await conn.query(
        'DELETE FROM users WHERE username = ?',
        [username]
      );
      
      return result.affectedRows! > 0;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
  
  Future<bool> toggleUserRole(String username) async {
    final conn = await connection;
    try {
      final user = await getUserByUsername(username);
      
      if (user == null) {
        return false;
      }
      
      final newRole = user.role == 'admin' ? 'user' : 'admin';
      final result = await conn.query(
        'UPDATE users SET role = ? WHERE username = ?',
        [newRole, username]
      );
      
      return result.affectedRows! > 0;
    } catch (e) {
      print('Error toggling user role: $e');
      return false;
    }
  }
  
  // Script methods
  Future<List<Script>> getAllScripts({String? searchQuery}) async {
    final conn = await connection;
    Results results;
    
    try {
      if (searchQuery != null && searchQuery.isNotEmpty) {
        results = await conn.query(
          'SELECT * FROM scripts WHERE LOWER(filename) LIKE ? ORDER BY upload_date DESC',
          ['%${searchQuery.toLowerCase()}%']
        );
      } else {
        results = await conn.query(
          'SELECT * FROM scripts ORDER BY upload_date DESC'
        );
      }
      
      return results.map((row) => Script(
        id: row['id'] as int? ?? 0,
        filename: row['filename'] as String? ?? 'unnamed_script',
        // Convertir de Blob a String si es necesario
        content: row['content'] is Blob 
            ? String.fromCharCodes((row['content'] as Blob).toBytes())
            : (row['content'] ?? '').toString(),
        uploadDate: row['upload_date'] as DateTime? ?? DateTime.now(),
        modifiedDate: row['modified_date'] as DateTime?,
        lastExecution: row['last_execution'] as DateTime?,
        executionCount: row['execution_count'] as int? ?? 0,
        downloads: row['downloads'] as int? ?? 0,
        uploadedBy: row['uploaded_by'] as String? ?? 'Unknown',
      )).toList();
    } catch (e) {
      print('Error getting all scripts: $e');
      return [];
    }
  }
  
  Future<Script?> getScriptById(int id) async {
    final conn = await connection;
    try {
      final results = await conn.query(
        'SELECT * FROM scripts WHERE id = ?',
        [id]
      );
      
      if (results.isEmpty) {
        return null;
      }
      
      final row = results.first;
      return Script(
        id: row['id'] as int? ?? 0,
        filename: row['filename'] as String? ?? 'unnamed_script',
        // Convertir de Blob a String si es necesario
        content: row['content'] is Blob 
            ? String.fromCharCodes((row['content'] as Blob).toBytes())
            : (row['content'] ?? '').toString(),
        uploadDate: row['upload_date'] as DateTime? ?? DateTime.now(),
        modifiedDate: row['modified_date'] as DateTime?,
        lastExecution: row['last_execution'] as DateTime?,
        executionCount: row['execution_count'] as int? ?? 0,
        downloads: row['downloads'] as int? ?? 0,
        uploadedBy: row['uploaded_by'] as String? ?? 'Unknown',
      );
    } catch (e) {
      print('Error getting script by ID: $e');
      return null;
    }
  }
  
  Future<int> addScript(String filename, String content, String uploadedBy) async {
    final conn = await connection;
    final now = DateTime.now().toUtc().toIso8601String();
    
    try {
      final result = await conn.query(
        'INSERT INTO scripts (filename, content, upload_date, uploaded_by) VALUES (?, ?, ?, ?)',
        [filename, content, now, uploadedBy]
      );
      
      return result.insertId ?? 0;
    } catch (e) {
      print('Error adding script: $e');
      return -1;
    }
  }
  
  Future<bool> updateScript(int id, String content) async {
    final conn = await connection;
    final now = DateTime.now().toUtc().toIso8601String();
    
    try {
      final result = await conn.query(
        'UPDATE scripts SET content = ?, modified_date = ? WHERE id = ?',
        [content, now, id]
      );
      
      return result.affectedRows! > 0;
    } catch (e) {
      print('Error updating script: $e');
      return false;
    }
  }
  
  Future<bool> deleteScript(int id) async {
    final conn = await connection;
    
    try {
      // Delete related execution logs first
      await conn.query(
        'DELETE FROM execution_logs WHERE script_id = ?',
        [id]
      );
      
      final result = await conn.query(
        'DELETE FROM scripts WHERE id = ?',
        [id]
      );
      
      return result.affectedRows! > 0;
    } catch (e) {
      print('Error deleting script: $e');
      return false;
    }
  }
  
  Future<bool> deleteAllScripts() async {
    final conn = await connection;
    
    try {
      // Delete all execution logs first
      await conn.query('DELETE FROM execution_logs');
      
      final result = await conn.query('DELETE FROM scripts');
      return result.affectedRows! > 0;
    } catch (e) {
      print('Error deleting all scripts: $e');
      return false;
    }
  }
  
  Future<bool> incrementDownloadCount(int scriptId) async {
    final conn = await connection;
    try {
      final result = await conn.query(
        'UPDATE scripts SET downloads = downloads + 1 WHERE id = ?',
        [scriptId]
      );
      
      return result.affectedRows! > 0;
    } catch (e) {
      print('Error incrementing download count: $e');
      return false;
    }
  }
  
  Future<bool> updateScriptExecution(int scriptId, bool success, String username) async {
    final conn = await connection;
    final now = DateTime.now().toUtc().toIso8601String();
    
    try {
      // Update script execution stats
      if (success) {
        await conn.query(
          'UPDATE scripts SET execution_count = execution_count + 1, last_execution = ? WHERE id = ?',
          [now, scriptId]
        );
      }
      
      // Add to execution logs
      final result = await conn.query(
        'INSERT INTO execution_logs (script_id, username, execution_date, success) VALUES (?, ?, ?, ?)',
        [scriptId, username, now, success ? 1 : 0]
      );
      
      return result.insertId != null;
    } catch (e) {
      print('Error updating script execution: $e');
      return false;
    }
  }
  
  Future<List<ExecutionLog>> getUserExecutionLogs(String username) async {
    final conn = await connection;
    try {
      final results = await conn.query('''
        SELECT e.*, s.filename 
        FROM execution_logs e 
        JOIN scripts s ON e.script_id = s.id 
        WHERE e.username = ? 
        ORDER BY e.execution_date DESC
      ''', [username]);
      
      return results.map((row) => ExecutionLog(
        id: row['id'] as int? ?? 0,
        scriptId: row['script_id'] as int? ?? 0,
        username: row['username'] as String? ?? '',
        executionDate: row['execution_date'] as DateTime? ?? DateTime.now(),
        success: (row['success'] as int? ?? 0) == 1,
        scriptName: row['filename'] as String?,
      )).toList();
    } catch (e) {
      print('Error getting user execution logs: $e');
      return [];
    }
  }
}