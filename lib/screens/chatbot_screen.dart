import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });
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

  @override
  void initState() {
    super.initState();
    _addSuggestedPrompts();
  }

  void _addSuggestedPrompts() {
    setState(() {
      // Añadir chatMessage de sistema con sugerencias
      _messages.add(ChatMessage(
        content:
            "¡Hola! Soy tu asistente de código DeepSeek. Puedes preguntarme sobre Python, PowerShell, o pedirme ayuda con tus scripts.\n\nAlgunas sugerencias:\n- Escribe un script para listar archivos en un directorio\n- Cómo leer un CSV en Python\n- Cómo hacer un backup automático con PowerShell",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
      // Prepare request payload
      final payload = {
        'model': 'deepseek-coder:1.3b',
        'prompt': text,
        'stream': false, // Cambiado a false para manejar mejor la codificación
        'context': _chatHistory.length > 1
            ? _chatHistory.sublist(0, _chatHistory.length - 1)
            : [],
        'options': {'temperature': 0.7, 'top_p': 0.9, 'num_predict': 1000}
      };

      // Hacer solicitud a Ollama API (no streaming)
      final response = await http.post(
        Uri.parse(_ollamaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // Decodificar la respuesta JSON
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        final String aiResponse = data['response'] ?? '';

        setState(() {
          aiMessage.content = aiResponse;
          aiMessage.isLoading = false;
        });

        // Update chat history with AI response
        _chatHistory.add({'role': 'assistant', 'content': aiResponse});
      } else {
        setState(() {
          aiMessage.content = 'Error ${response.statusCode}: ${response.body}';
          aiMessage.isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        aiMessage.content = 'Error connecting to AI service: $e';
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
                            onTap: _sendMessage,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
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

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String username;

  const _ChatBubble({
    Key? key,
    required this.message,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isUser = message.isUser;

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
                    username,
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
                  child: message.isLoading
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
                      : SelectableText(
                          message.content,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : themeProvider.textColor(context),
                          ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
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
