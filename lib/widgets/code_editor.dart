import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../utils/theme_provider.dart';

class CodeEditor extends StatefulWidget {
  final String code;
  final ValueChanged<String> onChanged;
  final String language;
  final bool readOnly;
  
  const CodeEditor({
    Key? key,
    required this.code,
    required this.onChanged,
    required this.language,
    this.readOnly = false,
  }) : super(key: key);

  @override
  _CodeEditorState createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
  }
  
  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != _controller.text) {
      _controller.text = widget.code;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleCodeChanged() {
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Simplificamos el editor usando sólo TextField para ambos modos
    return Container(
      color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9),
      child: TextField(
        controller: _controller,
        onChanged: (_) => _handleCodeChanged(),
        maxLines: null,
        readOnly: widget.readOnly,
        style: TextStyle(
          fontFamily: 'Consolas, Monaco, Courier New, monospace',
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintText: 'Enter your code here...',
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9),
        ),
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
      ),
    );
  }
}