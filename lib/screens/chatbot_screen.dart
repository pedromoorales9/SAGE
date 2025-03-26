import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math' as math;

import '../utils/localization.dart';
import '../utils/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/apple_button.dart';

class ChatMessage {
  // Cambiado de final a String normal para que sea mutable
  String content;
  final bool isUser;
  final DateTime timestamp;
  bool isLoading;
  // Nuevo: Controlador para la animación de escritura
  final StreamController<String> typingController = StreamController<String>();

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  // Cerrar el controlador al finalizar
  void dispose() {
    typingController.close();
  }
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final String _ollamaUrl = "http://localhost:11434/api/generate";
  final List<Map<String, String>> _chatHistory = [];
  // Nuevas variables para controlar la velocidad de escritura
  // Velocidad base para la simulación de escritura (ajustada a un valor más realista)
  final Duration _typingDelay = Duration(milliseconds: 25);

  @override
  void initState() {
    super.initState();
    _addSuggestedPrompts();
  }

  void _addSuggestedPrompts() {
    setState(() {
      // Añadir chatMessage de sistema con sugerencias
      final initialMessage = ChatMessage(
        content:
            "¡Hola! Soy tu asistente de código DeepSeek. Puedes preguntarme sobre Python, PowerShell, o pedirme ayuda con tus scripts.\n\nAlgunas sugerencias:\n- Escribe un script para listar archivos en un directorio\n- Cómo leer un CSV en Python\n- Cómo hacer un backup automático con PowerShell",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(initialMessage);

      // Simular efecto de escritura para el mensaje inicial
      _simulateTyping(initialMessage);
    });
  }

  // Nueva función para simular el efecto de escritura
  Future<void> _simulateTyping(ChatMessage message) async {
    if (message.isUser) return; // Solo aplicar a mensajes de la IA

    final String fullText = message.content;
    message.content = '';

    // Simular escritura carácter por carácter con velocidad variable
    for (int i = 0; i < fullText.length; i++) {
      // Añadir el siguiente carácter
      setState(() {
        message.content = fullText.substring(0, i + 1);
      });
      message.typingController.add(message.content);
      _scrollToBottom();

      // Calcular retraso variable basado en puntuación y aleatoriedad
      int delay = _typingDelay.inMilliseconds;
      if (i < fullText.length - 1) {
        if ('.!?'.contains(fullText[i])) {
          delay *= 3; // Pausa mayor después de final de frase
        } else if (', ;:'.contains(fullText[i])) {
          delay *= 2; // Pausa media después de comas y punto y coma
        } else if (i > 0 && fullText[i - 1] == '\n' && fullText[i] == '\n') {
          delay *= 4; // Pausa extra entre párrafos
        } else {
          // Ligera variación aleatoria para que la escritura parezca humana
          delay += (delay * 0.5 * (math.Random().nextDouble() - 0.5)).toInt();
        }
      }

      await Future.delayed(Duration(milliseconds: delay));
    }

    // Marcar como completado
    setState(() {
      message.isLoading = false;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Limpiar todos los controladores de stream
    for (var message in _messages) {
      message.dispose();
    }
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);

    if (text.isEmpty || text == localization.getText('placeholder_chat')) {
      return;
    }

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Add AI placeholder message
    final aiMessage = ChatMessage(
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(aiMessage);
    });

    _scrollToBottom();

    // Update chat history
    _chatHistory.add({'role': 'user', 'content': text});

    try {
      // Prepare request payload - Ahora usamos streaming
      final payload = {
        'model': 'deepseek-coder:1.3b',
        'prompt': text,
        'stream': true, // Cambio principal: activar streaming
        'context': _chatHistory.length > 1
            ? _chatHistory.sublist(0, _chatHistory.length - 1)
            : [],
        'options': {'temperature': 0.7, 'top_p': 0.9, 'num_predict': 1000}
      };

      // Cliente para hacer streaming con soporte UTF-8 adecuado
      _httpClient = http.Client();
      final request = http.Request('POST', Uri.parse(_ollamaUrl));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(payload);

      final streamedResponse = await _httpClient.send(request);

      if (streamedResponse.statusCode == 200) {
        String completeResponse = '';

        // Crear un stream de bytes para procesar correctamente la codificación UTF-8
        final stream = streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (var line in stream) {
          if (line.trim().isEmpty) continue;

          try {
            final data = jsonDecode(line);
            final chunk = data['response'] ?? '';

            // Para que la escritura parezca más natural, procesamos carácter por carácter
            // con pequeñas variaciones en la velocidad
            for (int i = 0; i < chunk.length; i++) {
              completeResponse += chunk[i];

              // Actualizar el mensaje con cada carácter
              setState(() {
                aiMessage.content = completeResponse;
              });

              aiMessage.typingController.add(completeResponse);
              _scrollToBottom();

              // Variación aleatoria en la velocidad de escritura para efecto más natural
              // Los signos de puntuación causan pausas más largas
              int delay = _typingDelay.inMilliseconds;
              if ('.!?'.contains(chunk[i])) {
                delay *= 3; // Pausa mayor después de final de frase
              } else if (', ;:'.contains(chunk[i])) {
                delay *= 2; // Pausa media después de comas y punto y coma
              } else if (i > 0 && chunk[i - 1] == '\n' && chunk[i] == '\n') {
                delay *= 4; // Pausa extra entre párrafos
              } else {
                // Ligera variación aleatoria en la velocidad de escritura
                delay +=
                    (delay * 0.5 * (math.Random().nextDouble() - 0.5)).toInt();
              }

              await Future.delayed(Duration(milliseconds: delay));
            }
          } catch (e) {
            print('Error processing line: $e');
          }
        }

        setState(() {
          aiMessage.isLoading = false;
        });

        // Update chat history with AI response
        _chatHistory.add({'role': 'assistant', 'content': completeResponse});
      } else {
        // Manejar errores de la API
        setState(() {
          aiMessage.content =
              'Error ${streamedResponse.statusCode}: No se pudo conectar con el servicio de IA';
          aiMessage.isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        aiMessage.content = 'Error al conectar con el servicio de IA: $e';
        aiMessage.isLoading = false;
      });
    } finally {
      setState(() {
        _isTyping = false;
      });

      _scrollToBottom();
    }
  }

  void _clearChat() {
    // Cerrar todos los StreamControllers antes de limpiar
    for (var message in _messages) {
      message.dispose();
    }

    setState(() {
      _messages.clear();
      _chatHistory.clear();
      _addSuggestedPrompts();
    });
  }

  // Lista de prompts sugeridos para mostrar como chips
  final List<String> _promptSuggestions = [
    "Escribe un script para ordenar archivos",
    "Cómo leer un CSV en Python",
    "Ejemplo de función en PowerShell",
    "Cómo conectarme a una base de datos MySQL",
    "Script para hacer backup automático",
    "Genera un menú interactivo en Python"
  ];

  // Cliente HTTP para streaming
  late http.Client _httpClient;

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
                  _isTyping
                      ? "Typing..."
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
            child: Card(
              margin: const EdgeInsets.all(8),
              elevation: 3,
              color: themeProvider.cardBackground(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // Chatbot Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: themeProvider
                          .primaryButtonColor(context)
                          .withOpacity(0.1),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: themeProvider.primaryButtonColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Chatbot DeepSeek",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: themeProvider.textColor(context),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _clearChat,
                          icon: const Icon(Icons.delete_sweep),
                          label: Text(localization.getText('limpiar_chat')),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                themeProvider.secondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat Messages
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: themeProvider
                                        .secondaryTextColor(context)
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Start a conversation with DeepSeek Chatbot',
                                    style: TextStyle(
                                      color: themeProvider
                                          .secondaryTextColor(context),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];

                                return _ChatBubble(
                                  message: message,
                                  username: message.isUser
                                      ? authService.currentUser?.username ??
                                          'You'
                                      : 'DeepSeek AI',
                                );
                              },
                            ),
                    ),
                  ),

                  // Suggested prompts
                  if (_messages.isNotEmpty && _messages.length < 3)
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _promptSuggestions.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              label: Text(
                                _promptSuggestions[index].length > 20
                                    ? '${_promptSuggestions[index].substring(0, 20)}...'
                                    : _promptSuggestions[index],
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor:
                                  themeProvider.cardBackground(context),
                              onPressed: () {
                                setState(() {
                                  _messageController.text =
                                      _promptSuggestions[index];
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),

                  // Input Field
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.cardBackground(context),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10)),
                      border: Border(
                        top: BorderSide(
                          color: themeProvider.dividerColor(context),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText:
                                  localization.getText('placeholder_chat'),
                              filled: true,
                              fillColor: themeProvider.inputBackground(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: themeProvider.primaryButtonColor(context),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _isTyping ? null : _sendMessage,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: _isTyping
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ))
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final String username;

  const _ChatBubble({
    Key? key,
    required this.message,
    required this.username,
  }) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  // Variable para almacenar el contenido actual del mensaje
  String _currentContent = '';

  @override
  void initState() {
    super.initState();
    _currentContent = widget.message.content;

    // Suscribirse al stream de tipeo si no es un mensaje de usuario
    if (!widget.message.isUser) {
      widget.message.typingController.stream.listen((content) {
        if (mounted) {
          setState(() {
            _currentContent = content;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isUser = widget.message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: const Icon(
                Icons.smart_toy,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.username,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.secondaryTextColor(context),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? themeProvider.primaryButtonColor(context)
                        : themeProvider.inputBackground(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.message.isLoading && _currentContent.isEmpty
                      // Mostrar spinner solo si está cargando y no hay contenido
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUser
                                  ? Colors.white
                                  : themeProvider.primaryButtonColor(context),
                            ),
                          ),
                        )
                      // Contenido del mensaje con cursor parpadeante si está cargando
                      : Stack(
                          children: [
                            // Texto del mensaje con marcado para código
                            SelectableText.rich(
                              _buildFormattedText(_currentContent, isUser,
                                  themeProvider, context),
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : themeProvider.textColor(context),
                                height:
                                    1.5, // Mejor espaciado de línea para legibilidad
                              ),
                            ),
                            // Cursor parpadeante al final del texto
                            if (widget.message.isLoading && !isUser)
                              Positioned(
                                right: 0,
                                bottom:
                                    2, // Ajuste para alinear mejor con el texto
                                child: BlinkingCursor(
                                  color: isUser
                                      ? Colors.white
                                      : themeProvider.textColor(context),
                                ),
                              ),
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${widget.message.timestamp.hour}:${widget.message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: themeProvider.secondaryTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: themeProvider.primaryButtonColor(context),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Función para formatear el texto y resaltar código
TextSpan _buildFormattedText(String text, bool isUser,
    ThemeProvider themeProvider, BuildContext context) {
  // Buscar bloques de código (delimitados por ```)
  final RegExp codeBlockRegex = RegExp(r'```([\s\S]*?)```', multiLine: true);
  final List<InlineSpan> spans = [];

  int lastMatchEnd = 0;

  // Encontrar todos los bloques de código
  for (final Match match in codeBlockRegex.allMatches(text)) {
    // Añadir texto antes del bloque de código
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd, match.start),
      ));
    }

    // Extraer y formatear el código
    final String code = match.group(1) ?? '';
    spans.add(
      WidgetSpan(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUser
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            code.trim(),
            style: TextStyle(
              fontFamily: 'Consolas, Monaco, Courier New, monospace',
              color: isUser
                  ? Colors.white
                  : themeProvider.primaryButtonColor(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ),
    );

    lastMatchEnd = match.end;
  }

  // Añadir el resto del texto después del último bloque de código
  if (lastMatchEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastMatchEnd),
    ));
  }

  // Si no hay bloques de código, devolver solo el texto
  if (spans.isEmpty) {
    return TextSpan(text: text);
  }

  return TextSpan(children: spans);
}

// Cursor parpadeante separado como widget
class BlinkingCursor extends StatefulWidget {
  final Color color;

  const BlinkingCursor({
    Key? key,
    required this.color,
  }) : super(key: key);

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

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
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
        width: 2,
        height: 14,
        color: widget.color,
      ),
    );
  }
}
