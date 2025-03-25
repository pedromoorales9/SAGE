import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/script_service.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';
import '../utils/theme_provider.dart';
import '../models/script_model.dart';
import '../widgets/apple_button.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScriptService _scriptService = ScriptService(DatabaseService());
  List<ExecutionLog> _logs = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final username = authService.currentUser!.username;
      
      final logs = await _scriptService.getUserExecutionLogs(username);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error loading history: $e');
    }
  }
  
  Future<void> _exportHistory() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: localization.getText('export'),
        fileName: 'execution_history.txt',
      );
      
      if (outputPath != null) {
        final file = File(outputPath);
        final buffer = StringBuffer();
        
        // Add header
        buffer.writeln('Execution History - ${DateTime.now().toString()}');
        buffer.writeln('-------------------------------------');
        buffer.writeln();
        
        // Add logs
        for (final log in _logs) {
          final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
          final dateStr = dateFormat.format(log.executionDate);
          final status = log.success
              ? localization.getText('success')
              : 'Failure';
          
          buffer.writeln('$dateStr - ${log.scriptName} - $status');
        }
        
        await file.writeAsString(buffer.toString());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('history_exported')))
        );
      }
    } catch (e) {
      _showErrorDialog('Error exporting history: $e');
    }
  }
  
  void _showErrorDialog(String message) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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
                  localization.getText('history'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
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
            child: Card(
              margin: const EdgeInsets.all(8),
              elevation: 3,
              color: themeProvider.cardBackground(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryButtonColor(context).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: themeProvider.primaryButtonColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Execution History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: themeProvider.textColor(context),
                          ),
                        ),
                        const Spacer(),
                        AppleButton(
                          onPressed: _logs.isNotEmpty ? _exportHistory : null,
                          label: localization.getText('export'),
                          icon: Icons.download,
                          isPrimary: false,
                        ),
                        const SizedBox(width: 8),
                        AppleButton(
                          onPressed: _loadHistory,
                          label: localization.getText('refresh'),
                          icon: Icons.refresh,
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ),
                  
                  // History List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _logs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 64,
                                      color: themeProvider.secondaryTextColor(context).withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No execution history',
                                      style: TextStyle(
                                        color: themeProvider.secondaryTextColor(context),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your script execution history will appear here',
                                      style: TextStyle(
                                        color: themeProvider.secondaryTextColor(context),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
                                  return _HistoryListItem(log: log);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(8),
            color: themeProvider.cardBackground(context),
            child: Center(
              child: Text(
                localization.getText('created_by'),
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.secondaryTextColor(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final ExecutionLog log;
  
  const _HistoryListItem({
    super.key,
    required this.log,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: themeProvider.cardBackground(context).withOpacity(0.7),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: log.success
              ? themeProvider.successColor(context)
              : themeProvider.errorColor(context),
          child: Icon(
            log.success ? Icons.check : Icons.error,
            color: Colors.white,
          ),
        ),
        title: Text(
          log.scriptName ?? 'Unknown Script',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.textColor(context),
          ),
        ),
        subtitle: Text(
          dateFormat.format(log.executionDate),
          style: TextStyle(
            color: themeProvider.secondaryTextColor(context),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: log.success
                ? themeProvider.successColor(context).withOpacity(0.2)
                : themeProvider.errorColor(context).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            log.success ? 'Success' : 'Failed',
            style: TextStyle(
              color: log.success
                  ? themeProvider.successColor(context)
                  : themeProvider.errorColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}