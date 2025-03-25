import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/script_service.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';
import '../utils/theme_provider.dart';
import '../models/script_model.dart';
import '../widgets/apple_button.dart';
import '../widgets/code_editor.dart';

class ScriptsScreen extends StatefulWidget {
  const ScriptsScreen({Key? key}) : super(key: key);

  @override
  _ScriptsScreenState createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends State<ScriptsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScriptService _scriptService = ScriptService(DatabaseService());
  
  List<Script> _scripts = [];
  Script? _selectedScript;
  String _editorContent = '';
  String _executionOutput = '';
  bool _isExecuting = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadScripts();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadScripts() async {
    setState(() => _isLoading = true);
    
    try {
      final scripts = await _scriptService.getScripts();
      setState(() {
        _scripts = scripts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error loading scripts: $e');
    }
  }
  
  Future<void> _searchScripts() async {
    setState(() => _isLoading = true);
    
    try {
      final query = _searchController.text.trim();
      final scripts = await _scriptService.getScripts(
        searchQuery: query.isNotEmpty ? query : null
      );
      setState(() {
        _scripts = scripts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error searching scripts: $e');
    }
  }
  
  Future<void> _uploadScript() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final username = authService.currentUser!.username;
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['py', 'ps1'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final filename = result.files.first.name;
        final content = await file.readAsString();
        
        await _scriptService.uploadScript(filename, content, username);
        await _loadScripts();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('script_uploaded')))
        );
      }
    } catch (e) {
      _showErrorDialog('Error uploading script: $e');
    }
  }
  
  Future<void> _downloadScript() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText('select_script')))
      );
      return;
    }
    
    try {
      final filePath = await _scriptService.downloadScript(_selectedScript!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localization.getText('script_downloaded')}: $filePath'))
      );
    } catch (e) {
      _showErrorDialog('Error downloading script: $e');
    }
  }
  
  Future<void> _saveScript() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText('select_script')))
      );
      return;
    }
    
    if (_editorContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText('empty_script')))
      );
      return;
    }
    
    try {
      await _scriptService.saveScript(_selectedScript!.id, _editorContent);
      await _loadScripts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText('script_saved')))
      );
    } catch (e) {
      _showErrorDialog('Error saving script: $e');
    }
  }
  
  Future<void> _executeScript() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final username = authService.currentUser!.username;
    
    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText('select_script')))
      );
      return;
    }
    
    if (_editorContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText('empty_script')))
      );
      return;
    }
    
    // Check if script is safe to execute
    final isSafe = await _scriptService.isScriptSafe(_editorContent);
    
    if (!isSafe) {
      final shouldExecute = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localization.getText('warning')),
          content: Text(localization.getText('unsafe_script')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localization.getText('back')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(localization.getText('execute')),
            ),
          ],
        ),
      );
      
      if (shouldExecute != true) {
        return;
      }
    }
    
    setState(() {
      _isExecuting = true;
      // Usar un formato mejorado para la salida con estilo terminal
      _executionOutput = _formatExecutionHeader(_selectedScript!.filename);
    });
    
    try {
      // Make sure we're using the latest content
      final script = _selectedScript!.copyWith(content: _editorContent);
      
      final result = await _scriptService.executeScript(script, username);
      
      setState(() {
        if (result['stdout'] != null && result['stdout'].isNotEmpty) {
          _executionOutput += result['stdout'];
        }
        
        if (result['stderr'] != null && result['stderr'].isNotEmpty) {
          _executionOutput += '\n${_formatErrorOutput(localization.getText('errors'))}:\n${result['stderr']}';
        }
        
        if (result['success']) {
          _executionOutput += '\n\n${_formatSuccessOutput(localization.getText('success_msg'))}';
        } else {
          final exitCode = result['exitCode'] ?? -1;
          _executionOutput += '\n\n${_formatErrorOutput('Error (${localization.getText('code')}: $exitCode)')}';
        }
        
        _isExecuting = false;
      });
      
      await _loadScripts(); // Refresh to get updated stats
    } catch (e) {
      setState(() {
        _executionOutput += '\n\n${_formatErrorOutput(localization.getText('critical_error'))}: $e';
        _isExecuting = false;
      });
    }
  }
  
  // Métodos de formato para mejorar la salida visual
  String _formatExecutionHeader(String scriptName) {
    return "Ejecutando... [${scriptName}]\n\n";
  }

  String _formatSuccessOutput(String text) {
    return "✅ $text";
  }

  String _formatErrorOutput(String text) {
    return "❌ $text";
  }
  
  Future<void> _deleteScript() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can delete scripts'))
      );
      return;
    }
    
    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText('select_script')))
      );
      return;
    }
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.getText('confirm')),
        content: Text(localization.getText('confirm_delete_script')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localization.getText('back')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.errorColor(context),
            ),
            child: Text(localization.getText('delete_selected')),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      try {
        await _scriptService.deleteScript(_selectedScript!.id);
        
        setState(() {
          _scripts.removeWhere((s) => s.id == _selectedScript!.id);
          _selectedScript = null;
          _editorContent = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('script_deleted')))
        );
      } catch (e) {
        _showErrorDialog('Error deleting script: $e');
      }
    }
  }
  
  Future<void> _deleteAllScripts() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (!authService.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can delete all scripts'))
      );
      return;
    }
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.getText('confirm')),
        content: Text(localization.getText('confirm_delete_scripts')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localization.getText('back')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.errorColor(context),
            ),
            child: Text(localization.getText('delete_all')),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      try {
        await _scriptService.deleteAllScripts();
        
        setState(() {
          _scripts = [];
          _selectedScript = null;
          _editorContent = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('script_deleted')))
        );
      } catch (e) {
        _showErrorDialog('Error deleting all scripts: $e');
      }
    }
  }
  
  void _showScriptStats() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.getText('select_script')))
      );
      return;
    }
    
    final script = _selectedScript!;
    final never = localization.getText('never');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.getText('stats')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${script.filename}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('${localization.getText('uploaded')}: ${script.uploadDate.toLocal().toString().substring(0, 16)}'),
              Text('${localization.getText('by')}: ${script.uploadedBy}'),
              Text('${localization.getText('modified')}: ${script.modifiedDate != null ? script.modifiedDate!.toLocal().toString().substring(0, 16) : never}'),
              Text('${localization.getText('last_execution')}: ${script.lastExecution != null ? script.lastExecution!.toLocal().toString().substring(0, 16) : never}'),
              Text('${localization.getText('executed')}: ${script.executionCount} ${localization.getText('times')}'),
              Text('${localization.getText('downloaded')}: ${script.downloads} ${localization.getText('times')}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localization.getText('back')),
          ),
        ],
      ),
    );
  }
  
  void _selectScript(Script script) {
    setState(() {
      _selectedScript = script;
      _editorContent = script.content;
    });
  }
  
  void _showErrorDialog(String message) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.isAdmin;
    
    return Scaffold(
      backgroundColor: themeProvider.scaffoldBackground(context),
      body: Column(
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: themeProvider.cardBackground(context),
            child: Row(
              children: [
                Text(
                  _isExecuting 
                      ? localization.getText('executing')
                      : localization.getText('status_ready'),
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor(context),
                  ),
                ),
                const Spacer(),
                Text(
                  DateTime.now().toString().substring(0, 16),
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Panel - Script List
                SizedBox(
                  width: 300,
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 3,
                    color: themeProvider.cardBackground(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: localization.getText('search'),
                                    prefixIcon: const Icon(Icons.search),
                                    filled: true,
                                    fillColor: themeProvider.inputBackground(context),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onSubmitted: (_) => _searchScripts(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadScripts,
                              ),
                            ],
                          ),
                        ),
                        
                        // Scripts List
                        Expanded(
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : _scripts.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No scripts found',
                                        style: TextStyle(
                                          color: themeProvider.secondaryTextColor(context),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _scripts.length,
                                      itemBuilder: (context, index) {
                                        final script = _scripts[index];
                                        final isSelected = _selectedScript?.id == script.id;
                                        
                                        return ListTile(
                                          title: Text(script.filename),
                                          subtitle: Text(
                                            '${localization.getText('by')}: ${script.uploadedBy}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: themeProvider.secondaryTextColor(context),
                                            ),
                                          ),
                                          leading: Icon(
                                            script.filename.endsWith('.py')
                                                ? Icons.code
                                                : Icons.terminal,
                                            color: isSelected
                                                ? themeProvider.primaryButtonColor(context)
                                                : null,
                                          ),
                                          selected: isSelected,
                                          selectedTileColor: themeProvider.primaryButtonColor(context).withOpacity(0.1),
                                          onTap: () => _selectScript(script),
                                        );
                                      },
                                    ),
                        ),
                        
                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              AppleButton(
                                onPressed: _uploadScript,
                                label: localization.getText('upload'),
                                icon: Icons.upload_file,
                              ),
                              const SizedBox(height: 8),
                              AppleButton(
                                onPressed: _selectedScript != null ? _downloadScript : null,
                                label: localization.getText('download'),
                                icon: Icons.download,
                                isPrimary: false,
                              ),
                              if (isAdmin) ...[
                                const SizedBox(height: 8),
                                AppleButton(
                                  onPressed: _selectedScript != null ? _deleteScript : null,
                                  label: localization.getText('delete_selected'),
                                  icon: Icons.delete,
                                  isPrimary: false,
                                ),
                                const SizedBox(height: 8),
                                AppleButton(
                                  onPressed: _scripts.isNotEmpty ? _deleteAllScripts : null,
                                  label: localization.getText('delete_all'),
                                  icon: Icons.delete_forever,
                                  isPrimary: false,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Main Panel - Editor and Execution
                Expanded(
                  child: Column(
                    children: [
                      // Code Editor
                      Expanded(
                        flex: 3,
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          elevation: 3,
                          color: themeProvider.cardBackground(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              // Editor Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: themeProvider.primaryButtonColor(context).withOpacity(0.1),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedScript?.filename ?? 'No script selected',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.textColor(context),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.save),
                                      tooltip: localization.getText('save'),
                                      onPressed: _selectedScript != null ? _saveScript : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.info),
                                      tooltip: localization.getText('stats'),
                                      onPressed: _selectedScript != null ? _showScriptStats : null,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Code Editor
                              Expanded(
                                child: CodeEditor(
                                  code: _editorContent,
                                  onChanged: (newCode) {
                                    _editorContent = newCode;
                                  },
                                  language: _selectedScript?.filename.endsWith('.py') == true
                                      ? 'python'
                                      : 'powershell',
                                  readOnly: _selectedScript == null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Execution Output Area
                      Expanded(
                        flex: 2,
                        child: Card(
                          margin: const EdgeInsets.all(8),
                          elevation: 3,
                          color: themeProvider.cardBackground(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              // Output Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: themeProvider.cardBackground(context),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      localization.getText('execute'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.textColor(context),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Clear output button
                                    IconButton(
                                      icon: const Icon(Icons.clear_all),
                                      tooltip: 'Limpiar salida',
                                      onPressed: () {
                                        setState(() {
                                          _executionOutput = '';
                                        });
                                      },
                                    ),
                                    // Copy output button
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      tooltip: 'Copiar al portapapeles',
                                      onPressed: _executionOutput.isNotEmpty 
                                          ? () {
                                              Clipboard.setData(ClipboardData(text: _executionOutput));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Salida copiada al portapapeles')),
                                              );
                                            }
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    // Execute button with apple style
                                    Container(
                                      height: 40,
                                      child: TextButton.icon(
                                        onPressed: !_isExecuting && _selectedScript != null 
                                            ? _executeScript
                                            : null,
                                        style: TextButton.styleFrom(
                                          backgroundColor: themeProvider.primaryButtonColor(context),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                        icon: _isExecuting 
                                            ? SizedBox(
                                                width: 16, 
                                                height: 16, 
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                )
                                              )
                                            : Icon(Icons.play_arrow, size: 16),
                                        label: Text(localization.getText('execute')),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Output Text
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Output text
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: SingleChildScrollView(
                                          child: SelectableText(
                                            _executionOutput,
                                            style: const TextStyle(
                                              fontFamily: 'Consolas, Monaco, Courier New',
                                              color: Colors.lightGreenAccent,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Animación de escritura cuando está ejecutando
                                      if (_isExecuting)
                                        Positioned(
                                          bottom: 12,
                                          right: 12,
                                          child: Container(
                                            width: 8,
                                            height: 16,
                                            color: Colors.lightGreenAccent,
                                            child: const BlinkingCursor(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({Key? key}) : super(key: key);

  @override
  _BlinkingCursorState createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 16,
        color: Colors.lightGreenAccent,
      ),
    );
  }
}