import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:split_view/split_view.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as path;

import '../services/auth_service.dart';
import '../services/script_service.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';
import '../utils/theme_provider.dart';
import '../utils/responsive.dart';
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
  bool _isGridView = false; // Para alternar entre vista de lista y cuadrícula

  // Filtros
  bool _filterPython = false;
  bool _filterPowershell = false;
  bool _filterMyScripts = false;
  bool _filterFavorites = false;
  bool _filterRecent = false;
  String? _selectedTag;

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
      // Aplicar filtros si están activos
      String? fileType;
      if (_filterPython && !_filterPowershell) {
        fileType = 'py';
      } else if (_filterPowershell && !_filterPython) {
        fileType = 'ps1';
      }

      // Usuario actual para filtrar por "mis scripts"
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUsername =
          _filterMyScripts ? authService.currentUser?.username : null;

      final scripts = await _scriptService.getScripts(
        searchQuery:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        fileType: fileType,
        tag: _selectedTag,
        onlyFavorites: _filterFavorites,
        uploadedBy: currentUsername,
      );

      // Ordenar por fecha si está activado el filtro de recientes
      if (_filterRecent && scripts.isNotEmpty) {
        scripts.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      }

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

      // Aplicar filtros al buscar
      String? fileType;
      if (_filterPython && !_filterPowershell) {
        fileType = 'py';
      } else if (_filterPowershell && !_filterPython) {
        fileType = 'ps1';
      }

      // Usuario actual para filtrar por "mis scripts"
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUsername =
          _filterMyScripts ? authService.currentUser?.username : null;

      final scripts = await _scriptService.getScripts(
        searchQuery: query.isNotEmpty ? query : null,
        fileType: fileType,
        tag: _selectedTag,
        onlyFavorites: _filterFavorites,
        uploadedBy: currentUsername,
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
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);
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
            SnackBar(content: Text(localization.getText('script_uploaded'))));
      }
    } catch (e) {
      _showErrorDialog('Error uploading script: $e');
    }
  }

  Future<void> _downloadScript() async {
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);

    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('select_script'))));
      return;
    }

    try {
      final filePath = await _scriptService.downloadScript(_selectedScript!);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('${localization.getText('script_downloaded')}: $filePath')));
    } catch (e) {
      _showErrorDialog('Error downloading script: $e');
    }
  }

  Future<void> _saveScript() async {
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);

    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('select_script'))));
      return;
    }

    if (_editorContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('empty_script'))));
      return;
    }

    try {
      await _scriptService.saveScript(_selectedScript!.id, _editorContent);
      await _loadScripts();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('script_saved'))));
    } catch (e) {
      _showErrorDialog('Error saving script: $e');
    }
  }

  Future<void> _executeScript() async {
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final username = authService.currentUser!.username;

    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('select_script'))));
      return;
    }

    if (_editorContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('empty_script'))));
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
          _executionOutput +=
              '\n${_formatErrorOutput(localization.getText('errors'))}:\n${result['stderr']}';
        }

        if (result['success']) {
          _executionOutput +=
              '\n\n${_formatSuccessOutput(localization.getText('success_msg'))}';
        } else {
          final exitCode = result['exitCode'] ?? -1;
          _executionOutput +=
              '\n\n${_formatErrorOutput('Error (Código: $exitCode)')}';
        }

        _isExecuting = false;
      });

      await _loadScripts(); // Refresh to get updated stats
    } catch (e) {
      setState(() {
        _executionOutput +=
            '\n\n${_formatErrorOutput(localization.getText('critical_error'))}: $e';
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
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only admins can delete scripts')));
      return;
    }

    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('select_script'))));
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
            SnackBar(content: Text(localization.getText('script_deleted'))));
      } catch (e) {
        _showErrorDialog('Error deleting script: $e');
      }
    }
  }

  Future<void> _deleteAllScripts() async {
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only admins can delete all scripts')));
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
            SnackBar(content: Text(localization.getText('script_deleted'))));
      } catch (e) {
        _showErrorDialog('Error deleting all scripts: $e');
      }
    }
  }

  void _showScriptStats() {
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);

    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.getText('select_script'))));
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
              Text('${script.filename}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                  '${localization.getText('uploaded')}: ${script.uploadDate.toLocal().toString().substring(0, 16)}'),
              Text('${localization.getText('by')}: ${script.uploadedBy}'),
              Text(
                  '${localization.getText('modified')}: ${script.modifiedDate != null ? script.modifiedDate!.toLocal().toString().substring(0, 16) : never}'),
              Text(
                  '${localization.getText('last_execution')}: ${script.lastExecution != null ? script.lastExecution!.toLocal().toString().substring(0, 16) : never}'),
              Text(
                  '${localization.getText('executed')}: ${script.executionCount} ${localization.getText('times')}'),
              Text(
                  '${localization.getText('downloaded')}: ${script.downloads} ${localization.getText('times')}'),
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

  void _showTagsDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione un script primero')));
      return;
    }

    final textController = TextEditingController();
    if (_selectedScript!.tags.isNotEmpty) {
      textController.text = _selectedScript!.tags.join(', ');
    }

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestionar Etiquetas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Etiquetas (separadas por comas)',
                hintText: 'python, servidor, backup, etc.',
                filled: true,
                fillColor: themeProvider.inputBackground(context),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(themeProvider.borderRadiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
                'Las etiquetas te ayudan a organizar y filtrar tus scripts.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final tags = textController.text
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList();
              Navigator.of(context).pop(tags);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryButtonColor(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _scriptService.updateScriptTags(_selectedScript!.id, result);
        await _loadScripts();

        final script = _scripts.firstWhere((s) => s.id == _selectedScript!.id);
        setState(() {
          _selectedScript = script;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etiquetas actualizadas correctamente')),
        );
      } catch (e) {
        _showErrorDialog('Error al actualizar etiquetas: $e');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_selectedScript == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione un script primero')));
      return;
    }

    try {
      await _scriptService.toggleFavorite(_selectedScript!.id);
      await _loadScripts();

      // Actualizar el script seleccionado con la información actualizada
      final updatedScript =
          _scripts.firstWhere((s) => s.id == _selectedScript!.id);
      setState(() {
        _selectedScript = updatedScript;
      });

      final message = _selectedScript!.isFavorite
          ? 'Script añadido a favoritos'
          : 'Script eliminado de favoritos';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      _showErrorDialog('Error al cambiar estado de favoritos: $e');
    }
  }

  void _clearFilters() {
    setState(() {
      _filterPython = false;
      _filterPowershell = false;
      _filterMyScripts = false;
      _filterFavorites = false;
      _filterRecent = false;
      _selectedTag = null;
      _searchController.clear();
    });
    _loadScripts();
  }

  void _selectScript(Script script) {
    setState(() {
      _selectedScript = script;
      _editorContent = script.content;
    });
  }

  void _createNewScript() {
    // Implementar creación de nuevo script
    setState(() {
      _selectedScript = null;
      _editorContent = '';
      _executionOutput = '';
    });

    // Aquí podría mostrarse un diálogo para que el usuario ingrese el nombre del nuevo script
  }

  void _showErrorDialog(String message) {
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);

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

  void _showContextMenu(BuildContext context, Script script) {
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = authService.isAdmin;

    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx,
          position.dy + button.size.height,
          position.dx + button.size.width,
          position.dy + button.size.height * 2),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text(localization.getText('execute')),
            dense: true,
          ),
          onTap: () {
            _selectScript(script);
            Future.delayed(Duration.zero, _executeScript);
          },
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: Text('Editar'),
            dense: true,
          ),
          onTap: () {
            _selectScript(script);
          },
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.download),
            title: Text(localization.getText('download')),
            dense: true,
          ),
          onTap: () {
            _selectScript(script);
            Future.delayed(Duration.zero, _downloadScript);
          },
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(script.isFavorite ? Icons.star : Icons.star_border),
            title: Text(script.isFavorite
                ? 'Quitar de favoritos'
                : 'Añadir a favoritos'),
            dense: true,
          ),
          onTap: () {
            _selectScript(script);
            Future.delayed(Duration.zero, _toggleFavorite);
          },
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.label),
            title: Text('Gestionar etiquetas'),
            dense: true,
          ),
          onTap: () {
            _selectScript(script);
            Future.delayed(Duration.zero, _showTagsDialog);
          },
        ),
        if (isAdmin)
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.delete),
              title: Text(localization.getText('delete_selected')),
              dense: true,
            ),
            onTap: () {
              _selectScript(script);
              Future.delayed(Duration.zero, _deleteScript);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Wrap(
      spacing: 8.0,
      children: [
        FilterChip(
          label: const Text('Python'),
          selected: _filterPython,
          onSelected: (selected) {
            setState(() {
              _filterPython = selected;
              _loadScripts();
            });
          },
          backgroundColor: themeProvider.cardBackground(context),
          selectedColor:
              themeProvider.primaryButtonColor(context).withOpacity(0.2),
          checkmarkColor: themeProvider.primaryButtonColor(context),
        ),
        FilterChip(
          label: const Text('PowerShell'),
          selected: _filterPowershell,
          onSelected: (selected) {
            setState(() {
              _filterPowershell = selected;
              _loadScripts();
            });
          },
          backgroundColor: themeProvider.cardBackground(context),
          selectedColor:
              themeProvider.primaryButtonColor(context).withOpacity(0.2),
          checkmarkColor: themeProvider.primaryButtonColor(context),
        ),
        FilterChip(
          label: const Text('Mis Scripts'),
          selected: _filterMyScripts,
          onSelected: (selected) {
            setState(() {
              _filterMyScripts = selected;
              _loadScripts();
            });
          },
          backgroundColor: themeProvider.cardBackground(context),
          selectedColor:
              themeProvider.primaryButtonColor(context).withOpacity(0.2),
          checkmarkColor: themeProvider.primaryButtonColor(context),
        ),
        FilterChip(
          label: const Text('Favoritos'),
          selected: _filterFavorites,
          onSelected: (selected) {
            setState(() {
              _filterFavorites = selected;
              _loadScripts();
            });
          },
          backgroundColor: themeProvider.cardBackground(context),
          selectedColor:
              themeProvider.primaryButtonColor(context).withOpacity(0.2),
          checkmarkColor: themeProvider.primaryButtonColor(context),
          avatar: Icon(
            _filterFavorites ? Icons.star : Icons.star_border,
            size: 16,
            color: _filterFavorites
                ? themeProvider.primaryButtonColor(context)
                : themeProvider.secondaryTextColor(context),
          ),
        ),
        FilterChip(
          label: const Text('Recientes'),
          selected: _filterRecent,
          onSelected: (selected) {
            setState(() {
              _filterRecent = selected;
              _loadScripts();
            });
          },
          backgroundColor: themeProvider.cardBackground(context),
          selectedColor:
              themeProvider.primaryButtonColor(context).withOpacity(0.2),
          checkmarkColor: themeProvider.primaryButtonColor(context),
        ),
        ActionChip(
          label: const Text('Limpiar filtros'),
          onPressed: _clearFilters,
          backgroundColor: themeProvider.cardBackground(context),
          avatar: Icon(
            Icons.clear_all,
            size: 16,
            color: themeProvider.secondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isTabletOrDesktop =
        Responsive.isTablet(context) || Responsive.isDesktop(context);
    final columns =
        isTabletOrDesktop ? (Responsive.isDesktop(context) ? 3 : 2) : 1;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _scripts.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, index) {
        final script = _scripts[index];
        final isSelected = _selectedScript?.id == script.id;

        return GestureDetector(
          onSecondaryTap: () => _showContextMenu(context, script),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(themeProvider.borderRadiusMedium),
              side: isSelected
                  ? BorderSide(
                      color: themeProvider.primaryButtonColor(context),
                      width: 2,
                    )
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => _selectScript(script),
              borderRadius:
                  BorderRadius.circular(themeProvider.borderRadiusMedium),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          script.filename.endsWith('.py')
                              ? Icons.code
                              : Icons.terminal,
                          color: isSelected
                              ? themeProvider.primaryButtonColor(context)
                              : themeProvider.secondaryTextColor(context),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            script.filename,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? themeProvider.primaryButtonColor(context)
                                  : themeProvider.textColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (script.isFavorite)
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${script.uploadedBy} • ${_formatDate(script.uploadDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.secondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ejecutado ${script.executionCount} veces',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.secondaryTextColor(context),
                      ),
                    ),
                    const Spacer(),
                    if (script.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: script.tags
                            .map((tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return 'hace ${difference.inMinutes} minutos';
      }
      return 'hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.isAdmin;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO):
            const OpenIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const NewIntent(),
        LogicalKeySet(LogicalKeyboardKey.f5): const ExecuteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (intent) => _saveScript(),
          ),
          OpenIntent: CallbackAction<OpenIntent>(
            onInvoke: (intent) => _uploadScript(),
          ),
          NewIntent: CallbackAction<NewIntent>(
            onInvoke: (intent) => _createNewScript(),
          ),
          ExecuteIntent: CallbackAction<ExecuteIntent>(
            onInvoke: (intent) => _executeScript(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: themeProvider.scaffoldBackground(context),
            body: DropTarget(
              onDragDone: (details) async {
                // Manejar los archivos soltados
                for (final file in details.files) {
                  if (file.path.endsWith('.py') || file.path.endsWith('.ps1')) {
                    final content = await File(file.path).readAsString();
                    await _scriptService.uploadScript(path.basename(file.path),
                        content, authService.currentUser!.username);
                  }
                }
                _loadScripts(); // Recargar la lista de scripts
              },
              child: Column(
                children: [
                  // Status Bar
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                  // Main Content con Split View
                  Expanded(
                    child: SplitView(
                      viewMode: SplitViewMode.Horizontal,
                      controller: SplitViewController(weights: [0.25, 0.75]),
                      children: [
                        // Panel izquierdo (lista de scripts)
                        Card(
                          margin: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                          elevation: 3,
                          color: themeProvider.cardBackground(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              // Search Bar y Controles
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              hintText: localization
                                                  .getText('search'),
                                              prefixIcon:
                                                  const Icon(Icons.search),
                                              filled: true,
                                              fillColor: themeProvider
                                                  .inputBackground(context),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            onSubmitted: (_) =>
                                                _searchScripts(),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.refresh),
                                          onPressed: _loadScripts,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          tooltip: 'Nuevo script',
                                          onPressed: _createNewScript,
                                        ),
                                        // Toggle entre vista de lista y cuadrícula
                                        IconButton(
                                          icon: Icon(_isGridView
                                              ? Icons.list
                                              : Icons.grid_view),
                                          tooltip: _isGridView
                                              ? 'Vista de lista'
                                              : 'Vista de cuadrícula',
                                          onPressed: () {
                                            setState(() {
                                              _isGridView = !_isGridView;
                                            });
                                          },
                                        ),
                                        const Spacer(),
                                        PopupMenuButton<String?>(
                                          tooltip: 'Filtrar por etiqueta',
                                          icon: const Icon(Icons.label),
                                          onSelected: (tag) {
                                            setState(() {
                                              _selectedTag = tag;
                                              _loadScripts();
                                            });
                                          },
                                          itemBuilder: (context) {
                                            final allTags = _scripts
                                                .expand((script) => script.tags)
                                                .toSet()
                                                .toList()
                                              ..sort();

                                            return [
                                              const PopupMenuItem(
                                                value: null,
                                                child:
                                                    Text('Todas las etiquetas'),
                                              ),
                                              if (allTags.isNotEmpty)
                                                const PopupMenuDivider(),
                                              ...allTags
                                                  .map((tag) => PopupMenuItem(
                                                        value: tag,
                                                        child: Text(tag),
                                                      )),
                                            ];
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildFilterChips(),
                                  ],
                                ),
                              ),

                              // Scripts List
                              Expanded(
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : _scripts.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No scripts found',
                                              style: TextStyle(
                                                color: themeProvider
                                                    .secondaryTextColor(
                                                        context),
                                              ),
                                            ),
                                          )
                                        : _isGridView
                                            ? _buildGridView()
                                            : ListView.builder(
                                                itemCount: _scripts.length,
                                                itemBuilder: (context, index) {
                                                  final script =
                                                      _scripts[index];
                                                  final isSelected =
                                                      _selectedScript?.id ==
                                                          script.id;

                                                  return GestureDetector(
                                                    onSecondaryTap: () =>
                                                        _showContextMenu(
                                                            context, script),
                                                    child: ListTile(
                                                      title:
                                                          Text(script.filename),
                                                      subtitle: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '${localization.getText('by')}: ${script.uploadedBy}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: themeProvider
                                                                  .secondaryTextColor(
                                                                      context),
                                                            ),
                                                          ),
                                                          if (script
                                                              .tags.isNotEmpty)
                                                            Wrap(
                                                              spacing: 4,
                                                              children: script
                                                                  .tags
                                                                  .map(
                                                                      (tag) =>
                                                                          Chip(
                                                                            label:
                                                                                Text(tag, style: const TextStyle(fontSize: 10)),
                                                                            materialTapTargetSize:
                                                                                MaterialTapTargetSize.shrinkWrap,
                                                                            padding:
                                                                                EdgeInsets.zero,
                                                                            visualDensity:
                                                                                VisualDensity.compact,
                                                                          ))
                                                                  .toList(),
                                                            ),
                                                        ],
                                                      ),
                                                      leading: Icon(
                                                        script.filename
                                                                .endsWith('.py')
                                                            ? Icons.code
                                                            : Icons.terminal,
                                                        color: isSelected
                                                            ? themeProvider
                                                                .primaryButtonColor(
                                                                    context)
                                                            : null,
                                                      ),
                                                      trailing: script
                                                              .isFavorite
                                                          ? const Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.amber)
                                                          : null,
                                                      selected: isSelected,
                                                      selectedTileColor:
                                                          themeProvider
                                                              .primaryButtonColor(
                                                                  context)
                                                              .withOpacity(0.1),
                                                      onTap: () =>
                                                          _selectScript(script),
                                                    ),
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
                                      onPressed: _selectedScript != null
                                          ? _downloadScript
                                          : null,
                                      label: localization.getText('download'),
                                      icon: Icons.download,
                                      isPrimary: false,
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(height: 8),
                                      AppleButton(
                                        onPressed: _selectedScript != null
                                            ? _deleteScript
                                            : null,
                                        label: localization
                                            .getText('delete_selected'),
                                        icon: Icons.delete,
                                        isPrimary: false,
                                      ),
                                      const SizedBox(height: 8),
                                      AppleButton(
                                        onPressed: _scripts.isNotEmpty
                                            ? _deleteAllScripts
                                            : null,
                                        label:
                                            localization.getText('delete_all'),
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

                        // Panel derecho (editor + output) como Split View vertical
                        SplitView(
                          viewMode: SplitViewMode.Vertical,
                          controller: SplitViewController(weights: [0.6, 0.4]),
                          children: [
                            // Editor de código
                            Card(
                              margin: const EdgeInsets.fromLTRB(4, 8, 8, 4),
                              elevation: 3,
                              color: themeProvider.cardBackground(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  // Editor Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: themeProvider
                                          .primaryButtonColor(context)
                                          .withOpacity(0.1),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(10)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _selectedScript?.filename ??
                                              'No script selected',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: themeProvider
                                                .textColor(context),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(
                                              _selectedScript?.isFavorite ==
                                                      true
                                                  ? Icons.star
                                                  : Icons.star_border),
                                          tooltip:
                                              _selectedScript?.isFavorite ==
                                                      true
                                                  ? 'Quitar de favoritos'
                                                  : 'Añadir a favoritos',
                                          onPressed: _selectedScript != null
                                              ? _toggleFavorite
                                              : null,
                                          color: _selectedScript?.isFavorite ==
                                                  true
                                              ? Colors.amber
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.label),
                                          tooltip: 'Gestionar etiquetas',
                                          onPressed: _selectedScript != null
                                              ? _showTagsDialog
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.save),
                                          tooltip:
                                              '${localization.getText('save')} (Ctrl+S)',
                                          onPressed: _selectedScript != null
                                              ? _saveScript
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.info),
                                          tooltip:
                                              localization.getText('stats'),
                                          onPressed: _selectedScript != null
                                              ? _showScriptStats
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Code Editor
                                  Expanded(
                                    child: Container(
                                      height: double.infinity,
                                      padding: const EdgeInsets.all(4),
                                      child: CodeEditor(
                                        code: _editorContent,
                                        onChanged: (newCode) {
                                          _editorContent = newCode;
                                        },
                                        language: _selectedScript?.filename
                                                    .endsWith('.py') ==
                                                true
                                            ? 'python'
                                            : 'powershell',
                                        readOnly: _selectedScript == null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Output panel
                            Card(
                              margin: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                              elevation: 3,
                              color: themeProvider.cardBackground(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  // Output Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          themeProvider.cardBackground(context),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(10)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          localization.getText('execute'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: themeProvider
                                                .textColor(context),
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
                                                  Clipboard.setData(
                                                      ClipboardData(
                                                          text:
                                                              _executionOutput));
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Salida copiada al portapapeles')),
                                                  );
                                                }
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        // Execute button with apple style
                                        SizedBox(
                                          height: 40,
                                          child: TextButton.icon(
                                            onPressed: !_isExecuting &&
                                                    _selectedScript != null
                                                ? _executeScript
                                                : null,
                                            style: TextButton.styleFrom(
                                              backgroundColor: themeProvider
                                                  .primaryButtonColor(context),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                            ),
                                            icon: _isExecuting
                                                ? SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ))
                                                : const Icon(Icons.play_arrow,
                                                    size: 16),
                                            label: Text(localization
                                                .getText('execute')),
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
                                                  fontFamily:
                                                      'Consolas, Monaco, Courier New',
                                                  color:
                                                      Colors.lightGreenAccent,
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Barra de estado mejorada
            bottomNavigationBar: Container(
              height: 24,
              color: themeProvider.cardBackground(context),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Estado de la aplicación
                  Text(
                    _isExecuting
                        ? localization.getText('executing')
                        : localization.getText('status_ready'),
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor(context),
                    ),
                  ),

                  // Separador vertical
                  const SizedBox(width: 16),
                  const VerticalDivider(width: 1, thickness: 1),
                  const SizedBox(width: 16),

                  // Información del script actual
                  Text(
                    _selectedScript != null
                        ? '${_selectedScript!.filename} (${_selectedScript!.executionCount} ejecuciones)'
                        : 'No hay script seleccionado',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.secondaryTextColor(context),
                    ),
                  ),

                  // Espaciador
                  const Spacer(),

                  // Fecha y hora
                  Text(
                    DateTime.now().toString().substring(0, 19),
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
      ),
    );
  }
}

class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({Key? key}) : super(key: key);

  @override
  _BlinkingCursorState createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
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

// Define las clases de Intent para los atajos de teclado
class SaveIntent extends Intent {
  const SaveIntent();
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class NewIntent extends Intent {
  const NewIntent();
}

class ExecuteIntent extends Intent {
  const ExecuteIntent();
}
