import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/powershell.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
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
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    _initCodeController();
  }

  void _initCodeController() {
    // Determinar el lenguaje basado en la propiedad
    final language = widget.language == 'python' ? python : powershell;

    _codeController = CodeController(
      text: widget.code,
      language: language,
    );
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != _codeController.text) {
      _codeController.text = widget.code;
    }

    if (widget.language != oldWidget.language) {
      _initCodeController();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return CodeTheme(
      data: CodeThemeData(
        styles: isDarkMode ? monokaiSublimeTheme : githubTheme,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: CodeField(
          controller: _codeController,
          readOnly: widget.readOnly,
          onChanged: (text) => widget.onChanged(text),
          gutterStyle: GutterStyle(
            width: 48,
            margin: 16,
            textAlign: TextAlign.right,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Consolas, Monaco, Courier New, monospace',
            fontSize: 14,
          ),
          minLines: 10, // Mínimo número de líneas mostradas
          maxLines: null, // Sin límite de líneas (para permitir scroll)
        ),
      ),
    );
  }
}
