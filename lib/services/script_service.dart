import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';

import '../models/script_model.dart';
import 'database_service.dart';

class ScriptService {
  final DatabaseService _database;

  ScriptService(this._database);

  Future<List<Script>> getScripts({
    String? searchQuery,
    String? fileType,
    String? tag,
    bool? onlyFavorites,
    String? uploadedBy,
  }) async {
    return await _database.getAllScripts(
      searchQuery: searchQuery,
      fileType: fileType,
      tag: tag,
      onlyFavorites: onlyFavorites,
      uploadedBy: uploadedBy,
    );
  }

  Future<Script?> getScriptById(int id) async {
    return await _database.getScriptById(id);
  }

  Future<bool> saveScript(int id, String content) async {
    return await _database.updateScript(id, content);
  }

  Future<int> uploadScript(
      String filename, String content, String username) async {
    return await _database.addScript(filename, content, username);
  }

  Future<bool> deleteScript(int id) async {
    return await _database.deleteScript(id);
  }

  Future<bool> deleteAllScripts() async {
    return await _database.deleteAllScripts();
  }

  Future<String> downloadScript(Script script) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, script.filename);

    final file = File(filePath);
    await file.writeAsString(script.content);

    // Update download count
    await _database.incrementDownloadCount(script.id);

    return filePath;
  }

  Future<bool> isScriptSafe(String content) {
    final dangerousCommands = [
      'os.remove',
      'shutil.rmtree',
      'sys.exit',
      'Remove-Item',
      'rm -rf',
      'rmdir',
      'del ',
    ];

    return Future.value(!dangerousCommands.any((cmd) => content.contains(cmd)));
  }

  Future<Map<String, dynamic>> executeScript(
      Script script, String username) async {
    // Create temporary file
    final directory = await getTemporaryDirectory();
    final filePath = path.join(directory.path, script.filename);
    final file = File(filePath);
    await file.writeAsString(script.content);

    try {
      ProcessResult result;

      if (script.filename.endsWith('.py')) {
        result = await Process.run('python', [filePath]);
      } else if (script.filename.endsWith('.ps1')) {
        if (Platform.isWindows) {
          result = await Process.run('powershell', ['-File', filePath]);
        } else {
          return {
            'success': false,
            'stdout': '',
            'stderr': 'PowerShell scripts can only be executed on Windows.',
          };
        }
      } else {
        return {
          'success': false,
          'stdout': '',
          'stderr':
              'Unsupported file extension. Only .py and .ps1 are supported.',
        };
      }

      // Log execution
      await _database.updateScriptExecution(
        script.id,
        result.exitCode == 0,
        username,
      );

      return {
        'success': result.exitCode == 0,
        'stdout': result.stdout.toString(),
        'stderr': result.stderr.toString(),
        'exitCode': result.exitCode,
      };
    } catch (e) {
      return {
        'success': false,
        'stdout': '',
        'stderr': 'Execution error: ${e.toString()}',
      };
    } finally {
      // Clean up temporary file
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<List<ExecutionLog>> getUserExecutionLogs(String username) async {
    return await _database.getUserExecutionLogs(username);
  }

  Future<bool> updateScriptTags(int scriptId, List<String> tags) async {
    return await _database.updateScriptTags(scriptId, tags);
  }

  Future<bool> toggleFavorite(int scriptId) async {
    return await _database.toggleFavorite(scriptId);
  }

  Future<List<String>> getAllTags() async {
    return await _database.getAllTags();
  }
}
