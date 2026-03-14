import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/providers.dart';
import '../../models/book_model.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  final List<BookModel> availableBooks;
  
  const AIAssistantScreen({
    super.key,
    required this.availableBooks,
  });

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': 'Hello! I am your AI Book Assistant.\n\nTell me what kind of book you are looking for, your favorite genres, or even a specific topic you want to learn about, and I will recommend the best matches from our current catalog!',
    }
  ];
  
  bool _isLoading = false;

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
    final text = _promptController.text.trim();
    if (text.isEmpty) return;
    
    _promptController.clear();
    FocusScope.of(context).unfocus();
    
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    
    _scrollToBottom();
    
    final aiService = ref.read(aiServiceProvider);
    
    try {
      final response = await aiService.getBookRecommendations(text, widget.availableBooks);
      
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': response});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': 'I encountered an error while trying to process your request: $e'});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Text('SCH AI Assistant'),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                      ],
                      
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF1A3557) : Colors.white,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              topLeft: isUser ? const Radius.circular(20) : Radius.zero,
                              topRight: isUser ? Radius.zero : const Radius.circular(20),
                            ),
                            boxShadow: [
                              if (!isUser)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                            ],
                          ),
                          child: isUser 
                            ? Text(
                                message['text']!,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              )
                            : MarkdownBody(
                                data: message['text']!,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(color: Color(0xFF334155), fontSize: 15, height: 1.6),
                                  strong: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  listBullet: const TextStyle(color: Color(0xFF64748B)),
                                  tableHead: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  tableBody: const TextStyle(color: Color(0xFF334155), fontSize: 14),
                                  blockquote: const TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                                  code: TextStyle(
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    color: const Color(0xFF6366F1),
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                        ),
                      ),
                      
                      if (isUser) ...[
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFE2E8F0),
                          child: Icon(Icons.person, color: Color(0xFF64748B), size: 20),
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('AI is thinking...', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
          Container(
            padding: const EdgeInsets.all(16).copyWith(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: 'E.g., "Recommend a management book..."',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
