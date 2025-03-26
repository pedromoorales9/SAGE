import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/powershell.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../utils/theme_provider.dart';
import '../utils/localization.dart';

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
  bool _isFullScreen = false;
  String _searchText = '';
  String _replaceText = '';
  bool _isFindDialogOpen = false;
  bool _isReplaceDialogOpen = false;
  int _currentLineCount = 0;
  int _currentCharacterCount = 0;

  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Opciones de autocompletado para diferentes lenguajes
  final Map<String, List<String>> _autocompleteOptions = {
    'python': [
      'def ',
      'class ',
      'import ',
      'from ',
      'if ',
      'else:',
      'elif ',
      'for ',
      'while ',
      'try:',
      'except:',
      'finally:',
      'with ',
      'return ',
      'print(',
      'len(',
      'range(',
      'str(',
      'int(',
      'float('
    ],
    'powershell': [
      'function ',
      'if (',
      'else {',
      'elseif (',
      'foreach (',
      'while (',
      'try {',
      'catch {',
      'finally {',
      'switch (',
      'param(',
      '\$_',
      'Write-Host ',
      'Get-'
    ]
  };

  @override
  void initState() {
    super.initState();
    _initCodeController();
    _calculateStats();
  }

  void _initCodeController() {
    // Determinar el lenguaje basado en la propiedad
    final language = widget.language == 'python' ? python : powershell;

    _codeController = CodeController(
      text: widget.code,
      language: language,
    );

    // Añadir listener para actualizar estadísticas
    _codeController.addListener(_calculateStats);
  }

  void _calculateStats() {
    final text = _codeController.text;
    setState(() {
      _currentLineCount = '\n'.allMatches(text).length + 1;
      _currentCharacterCount = text.length;
    });
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != _codeController.text) {
      _codeController.text = widget.code;
      _calculateStats();
    }

    if (widget.language != oldWidget.language) {
      _codeController.removeListener(_calculateStats);
      _initCodeController();
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_calculateStats);
    _codeController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);

    setState(() {
      _isFindDialogOpen = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.getText('search')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Buscar texto',
                filled: true,
                fillColor: themeProvider.inputBackground(context),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(themeProvider.borderRadiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Encontrado(s): ${_calculateMatches(_searchText)}'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isFindDialogOpen = false;
              });
            },
            child: Text(localization.getText('back')),
          ),
          ElevatedButton(
            onPressed: () {
              _findAndHighlight(_searchText);
              Navigator.of(context).pop();
              setState(() {
                _isFindDialogOpen = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryButtonColor(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(themeProvider.borderRadiusSmall),
              ),
            ),
            child: Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _showReplaceDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);

    setState(() {
      _isReplaceDialogOpen = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buscar y Reemplazar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Buscar texto',
                filled: true,
                fillColor: themeProvider.inputBackground(context),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(themeProvider.borderRadiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Reemplazar con',
                filled: true,
                fillColor: themeProvider.inputBackground(context),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(themeProvider.borderRadiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _replaceText = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Encontrado(s): ${_calculateMatches(_searchText)}'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isReplaceDialogOpen = false;
              });
            },
            child: Text(localization.getText('back')),
          ),
          TextButton(
            onPressed: () {
              _findAndHighlight(_searchText);
              Navigator.of(context).pop();
              setState(() {
                _isReplaceDialogOpen = false;
              });
            },
            child: Text('Buscar'),
          ),
          ElevatedButton(
            onPressed: () {
              _replaceAll(_searchText, _replaceText);
              Navigator.of(context).pop();
              setState(() {
                _isReplaceDialogOpen = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryButtonColor(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(themeProvider.borderRadiusSmall),
              ),
            ),
            child: Text('Reemplazar Todo'),
          ),
        ],
      ),
    );
  }

  int _calculateMatches(String query) {
    if (query.isEmpty) return 0;
    final text = _codeController.text;
    final matches = query.allMatches(text);
    return matches.length;
  }

  void _findAndHighlight(String query) {
    if (query.isEmpty) return;

    final text = _codeController.text;
    final matches = query.allMatches(text).toList();

    if (matches.isNotEmpty) {
      // Mover el cursor y seleccionar el texto encontrado
      final match = matches.first;
      _codeController.selection = TextSelection(
        baseOffset: match.start,
        extentOffset: match.end,
      );

      // Asegurarse de que es visible en el editor
      // Esto es una aproximación, ya que el widget de código podría tener su propio scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // Cálculo aproximado de la posición para hacer scroll
          final lineHeight = 20.0; // Altura aproximada de una línea
          final linesBefore =
              '\n'.allMatches(text.substring(0, match.start)).length;
          _scrollController.animateTo(
            lineHeight * linesBefore,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _replaceAll(String search, String replace) {
    if (search.isEmpty) return;

    final text = _codeController.text;
    final newText = text.replaceAll(search, replace);

    if (text != newText) {
      _codeController.text = newText;
      widget.onChanged(newText);
      _calculateStats();
    }
  }

  void _formatCode() {
    // Esta es una implementación básica de formato
    // Un formateador real requeriría una biblioteca para cada lenguaje

    final text = _codeController.text;
    String formattedText = text;

    // Formateo simple para Python
    if (widget.language == 'python') {
      // Simplemente elimina espacios en blanco al final de las líneas
      formattedText =
          text.split('\n').map((line) => line.trimRight()).join('\n');
    }
    // Formateo simple para PowerShell
    else if (widget.language == 'powershell') {
      // Simplemente elimina espacios en blanco al final de las líneas
      formattedText =
          text.split('\n').map((line) => line.trimRight()).join('\n');
    }

    if (text != formattedText) {
      _codeController.text = formattedText;
      widget.onChanged(formattedText);
    }
  }

  void _changeIndentation(bool increase) {
    final text = _codeController.text;
    if (text.isEmpty) return;

    final lines = text.split('\n');

    // Obtener la selección actual
    final selection = _codeController.selection;

    // Validación de seguridad para evitar índices fuera de rango
    if (selection.baseOffset < 0 || selection.baseOffset > text.length) {
      return;
    }

    if (selection.isCollapsed) {
      // Si no hay selección, indentar la línea actual
      int currentLine = 0;
      int charCount = 0;

      // Calcular la línea actual de forma más segura
      for (int i = 0; i < lines.length; i++) {
        int lineLength = lines[i].length + 1; // +1 por el salto de línea
        if (charCount + lineLength > selection.baseOffset) {
          currentLine = i;
          break;
        }
        charCount += lineLength;
      }

      if (currentLine < lines.length) {
        if (increase) {
          lines[currentLine] = '  ' + lines[currentLine];
        } else if (lines[currentLine].startsWith('  ')) {
          lines[currentLine] = lines[currentLine].substring(2);
        } else if (lines[currentLine].startsWith('\t')) {
          lines[currentLine] = lines[currentLine].substring(1);
        }
      }
    } else {
      // Si hay selección, indentar todas las líneas seleccionadas
      // Primero, asegurémonos de que los offsets de selección son válidos
      final safeBaseOffset =
          math.max(0, math.min(selection.baseOffset, text.length));
      final safeExtentOffset =
          math.max(0, math.min(selection.extentOffset, text.length));

      // Calcular las líneas de forma segura
      final selectedText = text.substring(safeBaseOffset, safeExtentOffset);
      final selectedLines = selectedText.split('\n');

      int startLineIndex = 0;
      int charCount = 0;

      // Encontrar la línea inicial
      for (int i = 0; i < lines.length; i++) {
        int lineLength = lines[i].length + 1; // +1 por el salto de línea
        if (charCount + lineLength > safeBaseOffset) {
          startLineIndex = i;
          break;
        }
        charCount += lineLength;
      }

      // Indentar las líneas seleccionadas
      for (int i = 0;
          i < selectedLines.length && (startLineIndex + i) < lines.length;
          i++) {
        int lineIndex = startLineIndex + i;
        if (increase) {
          lines[lineIndex] = '  ' + lines[lineIndex];
        } else if (lines[lineIndex].startsWith('  ')) {
          lines[lineIndex] = lines[lineIndex].substring(2);
        } else if (lines[lineIndex].startsWith('\t')) {
          lines[lineIndex] = lines[lineIndex].substring(1);
        }
      }
    }

    final newText = lines.join('\n');
    if (text != newText) {
      _codeController.text = newText;
      widget.onChanged(newText);
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _showAutocompleteSuggestions() {
    final suggestions = _autocompleteOptions[widget.language] ?? [];
    if (suggestions.isEmpty) return;

    final currentPosition = _codeController.selection.baseOffset;
    if (currentPosition <= 0 || currentPosition > _codeController.text.length)
      return;

    final text = _codeController.text;

    // Determina la palabra actual basada en la posición del cursor
    int wordStart = currentPosition;
    while (wordStart > 0 &&
        text[wordStart - 1] != ' ' &&
        text[wordStart - 1] != '\n') {
      wordStart--;
    }

    if (wordStart < 0 || wordStart >= currentPosition) return;

    final currentWord = text.substring(wordStart, currentPosition);
    if (currentWord.isEmpty) return;

    // Filtra sugerencias que coincidan con la palabra actual
    final matchingSuggestions = suggestions
        .where((s) => s.toLowerCase().startsWith(currentWord.toLowerCase()))
        .toList();

    if (matchingSuggestions.isEmpty) return;

    // Calcular posición aproximada
    final position = RelativeRect.fromLTRB(100, 100, 100, 100);

    // Mostrar menú de sugerencias
    showMenu(
      context: context,
      position: position,
      items: matchingSuggestions
          .map((suggestion) => PopupMenuItem(
                value: suggestion,
                child: Text(suggestion),
              ))
          .toList(),
    ).then((selectedValue) {
      if (selectedValue != null) {
        try {
          // Reemplazar la palabra actual con la sugerencia
          final newText =
              text.replaceRange(wordStart, currentPosition, selectedValue);
          _codeController.text = newText;
          widget.onChanged(newText);

          // Colocar el cursor al final de la sugerencia insertada
          _codeController.selection = TextSelection.fromPosition(
              TextPosition(offset: wordStart + selectedValue.length));
        } catch (e) {
          print('Error al aplicar sugerencia: $e');
        }
      }
    });
  }

  int _calculateLineCount() {
    return _currentLineCount;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return Column(
      children: [
        // Barra de herramientas avanzada
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: themeProvider.spacingSmall,
              vertical: themeProvider.spacingTiny),
          decoration: BoxDecoration(
            color: themeProvider.cardBackground(context).withOpacity(0.9),
            border: Border(
                bottom: BorderSide(color: themeProvider.dividerColor(context))),
          ),
          child: Row(
            children: [
              // Buscar y reemplazar
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                tooltip: 'Buscar en el código',
                onPressed: widget.readOnly ? null : () => _showSearchDialog(),
              ),
              IconButton(
                icon: const Icon(Icons.find_replace, size: 20),
                tooltip: 'Buscar y reemplazar',
                onPressed: widget.readOnly ? null : () => _showReplaceDialog(),
              ),

              VerticalDivider(
                width: themeProvider.spacingMedium,
                color: themeProvider.dividerColor(context),
              ),

              // Formato del código
              IconButton(
                icon: const Icon(Icons.format_align_left, size: 20),
                tooltip: 'Formatear código',
                onPressed: widget.readOnly ? null : () => _formatCode(),
              ),

              // Indentación
              IconButton(
                icon: const Icon(Icons.format_indent_increase, size: 20),
                tooltip: 'Aumentar indentación',
                onPressed:
                    widget.readOnly ? null : () => _changeIndentation(true),
              ),
              IconButton(
                icon: const Icon(Icons.format_indent_decrease, size: 20),
                tooltip: 'Disminuir indentación',
                onPressed:
                    widget.readOnly ? null : () => _changeIndentation(false),
              ),

              VerticalDivider(
                width: themeProvider.spacingMedium,
                color: themeProvider.dividerColor(context),
              ),

              // Autocompletar
              IconButton(
                icon: const Icon(Icons.auto_awesome, size: 20),
                tooltip: 'Sugerencias de código',
                onPressed: widget.readOnly
                    ? null
                    : () => _showAutocompleteSuggestions(),
              ),

              VerticalDivider(
                width: themeProvider.spacingMedium,
                color: themeProvider.dividerColor(context),
              ),

              // Modos
              IconButton(
                icon: Icon(
                    _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    size: 20),
                tooltip: _isFullScreen
                    ? 'Salir de pantalla completa'
                    : 'Modo pantalla completa',
                onPressed: () => _toggleFullScreen(),
              ),

              const Spacer(),

              // Información
              Text(
                '$_currentLineCount líneas | ${widget.language}',
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.secondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),

        // Editor de código
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(
              styles: isDarkMode ? monokaiSublimeTheme : githubTheme,
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
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
          ),
        ),
      ],
    );
  }
}
