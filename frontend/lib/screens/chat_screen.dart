import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/api_service.dart';
import '../main.dart';

import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final String threadId;
  
  const ChatScreen({super.key, required this.prefs, this.threadId = "default"});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _imageBase64;
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _handsFreeMode = false;
  Timer? _handsFreeTimer;

  String get _storageKey => 'chat_thread_${widget.threadId}';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initSpeech();
  }

  void _initSpeech() async {
    _isSpeechInitialized = await _speech.initialize();
  }

  void _startListening() async {
    if (!_isSpeechInitialized) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        _controller.text = result.recognizedWords;
        if (result.finalResult) {
          setState(() => _isListening = false);
          if (_handsFreeMode && result.recognizedWords.toLowerCase().startsWith("hey securai")) {
            _controller.text = result.recognizedWords.substring(11).trim();
            _sendMessage();
          } else if (!_handsFreeMode) {
            _sendMessage();
          }
        }
      },
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _toggleHandsFree(bool value) {
    setState(() {
      _handsFreeMode = value;
      if (_handsFreeMode) {
        _startListening();
        _handsFreeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (!_isListening && _handsFreeMode) {
            _startListening();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hands-Free Mode Enabled. Say "Hey SecurAI..."')));
      } else {
        _handsFreeTimer?.cancel();
        _stopListening();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hands-Free Mode Disabled.')));
      }
    });
  }

  @override
  void dispose() {
    _handsFreeTimer?.cancel();
    super.dispose();
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(bytes);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image Attached for Vision AI!')));
      });
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'log', 'json', 'csv', 'yaml', 'md'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String contents = await file.readAsString();
      
      if (contents.length > 5000) {
        contents = "${contents.substring(0, 5000)}\n...[TRUNCATED]";
      }
      
      setState(() {
        _controller.text = "Please analyze this file: ${result.files.single.name}\n\n```\n$contents\n```\n";
      });
    }
  }

  Future<void> _loadMessages() async {
    if (widget.threadId == "default") return;
    
    try {
      final response = await supabase
          .from('chat_messages')
          .select()
          .eq('session_id', widget.threadId)
          .order('created_at', ascending: true);
          
      setState(() {
        _messages = response.map<Map<String, String>>((row) => {
          "sender": row['role'],
          "text": row['content']
        }).toList();
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading messages: $e")));
    }
  }

  Future<void> _saveMessageToCloud(String role, String content) async {
    if (widget.threadId == "default") return;
    try {
      await supabase.from('chat_messages').insert({
        'session_id': widget.threadId,
        'user_id': supabase.auth.currentUser!.id,
        'role': role,
        'content': content
      });
    } catch (e) {
      debugPrint("Error saving message: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) async {
    final userMsg = text ?? _controller.text.trim();
    if (userMsg.isEmpty && _imageBase64 == null) return;
    
    if (widget.threadId == "default") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please start a New Chat from the menu first!")));
      return;
    }
    
    final b64 = _imageBase64;
    final displayMsg = userMsg.isEmpty ? "[Image Attached]" : userMsg;

    setState(() {
      _messages.add({"sender": "user", "text": displayMsg});
      _messages.add({"sender": "ai", "text": ""});
      _controller.clear();
      _imageBase64 = null;
      _isLoading = true;
    });
    
    await _saveMessageToCloud("user", displayMsg);
    _scrollToBottom();

    final persona = widget.prefs.getString('persona') ?? "auditor";
    final language = widget.prefs.getString('language') ?? "English";
    final stream = _apiService.streamMessage(userMsg, persona, language, imageBase64: b64);
    
    String fullAiResponse = "";
    
    await for (final chunk in stream) {
      fullAiResponse += chunk;
      setState(() {
        _messages.last["text"] = fullAiResponse;
      });
      _scrollToBottom();
    }

    await _saveMessageToCloud("ai", fullAiResponse);

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildEmptyState() {
    final suggestions = [
      "How to secure an Express.js API?",
      "Explain SQL Injection",
      "Best practices for Docker containers?",
      "Write a secure login function in Python",
    ];

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              Text(
                "Welcome to SecurAI Copilot",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Your AI-powered DevSecOps assistant.\nAsk me anything about code security, deployment, and best practices.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: suggestions.map((text) {
                  return ActionChip(
                    label: Text(text),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    onPressed: () => _sendMessage(text),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSystemStatus() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<Map<String, dynamic>>(
          stream: _apiService.streamMetrics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
            }
            final metrics = snapshot.data;
            if (metrics == null) {
              return const SizedBox(height: 250, child: Center(child: Text('Could not fetch system status.', style: TextStyle(color: Colors.redAccent))));
            }
            
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security, color: Colors.cyanAccent),
                      SizedBox(width: 8),
                      Text('Live Security & Health Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildStatusRow('System Health', '${(metrics['system_health'] ?? 0).toStringAsFixed(1)}%', Icons.favorite, Colors.greenAccent),
                  const SizedBox(height: 16),
                  _buildStatusRow('CPU Usage', '${(metrics['cpu_percent'] ?? 0).toStringAsFixed(1)}%', Icons.memory, Colors.orangeAccent),
                  const SizedBox(height: 16),
                  _buildStatusRow('Memory Usage', '${(metrics['ram_percent'] ?? 0).toStringAsFixed(1)}%', Icons.storage, Colors.purpleAccent),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildStatusRow(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Text(title, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildChatBubble(Map<String, String> msg, int index) {
    final isUser = msg["sender"] == "user";
    final theme = Theme.of(context);
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser 
              ? theme.colorScheme.primary.withValues(alpha: 0.15) 
              : (theme.brightness == Brightness.dark ? const Color(0xFF0D0D12) : theme.colorScheme.surface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 16),
          ),
          border: Border.all(
            color: isUser ? theme.colorScheme.primary : theme.colorScheme.secondary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? theme.colorScheme.primary : theme.colorScheme.secondary).withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: isUser 
                ? SelectableText(
                    msg["text"]!,
                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                  )
                : MarkdownBody(
                    data: msg["text"]!.isEmpty ? "..." : msg["text"]!,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: theme.colorScheme.onSurface),
                      code: TextStyle(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: theme.colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
            ),
            if (!isUser && !(_isLoading && index == _messages.length - 1))
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: msg["text"]!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      tooltip: "Copy Text",
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 16, color: Colors.grey),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AI response ready to share!')),
                        );
                      },
                      tooltip: "Share",
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('SecurAI Copilot', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          Row(
            children: [
              const Text('Hands-Free', style: TextStyle(fontSize: 12, color: Colors.cyanAccent)),
              Switch(
                value: _handsFreeMode,
                onChanged: _toggleHandsFree,
                activeColor: Colors.cyanAccent,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _showSystemStatus,
            tooltip: 'System Status',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.history, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text('Chat History', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_messages.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No history yet.", style: TextStyle(color: Colors.grey)),
                )
              else
                ..._messages.where((m) => m["sender"] == "user").map((msg) {
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: Colors.cyanAccent),
                    title: Text(
                      msg["text"]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  );
                }),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildChatBubble(_messages[index], index);
                  },
                ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Colors.grey),
                            padding: const EdgeInsets.only(left: 12, right: 4, top: 12, bottom: 12),
                            constraints: const BoxConstraints(),
                            onPressed: _pickFile,
                            tooltip: "Upload File",
                          ),
                          IconButton(
                            icon: Icon(Icons.camera_alt, color: _imageBase64 != null ? Colors.cyanAccent : Colors.grey),
                            padding: const EdgeInsets.only(left: 4, right: 8, top: 12, bottom: 12),
                            constraints: const BoxConstraints(),
                            onPressed: _pickImage,
                            tooltip: "Upload Image for Vision AI",
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 5,
                              textInputAction: TextInputAction.newline,
                              decoration: const InputDecoration(
                                hintText: 'Message SecurAI...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.grey),
                            padding: const EdgeInsets.only(left: 8, right: 12, top: 12, bottom: 12),
                            constraints: const BoxConstraints(),
                            onPressed: _isListening ? _stopListening : _startListening,
                            tooltip: "Voice to Text",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : () => _sendMessage(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
