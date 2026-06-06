import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/gemini_service.dart';
import '../../widgets/ad_banner_widget.dart';
import 'widgets/chat_bubble.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String> sources;
  final List<String> relatedFacts;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.sources      = const [],
    this.relatedFacts = const [],
  });
}

class AskIQScreen extends StatefulWidget {
  const AskIQScreen({super.key});

  @override
  State<AskIQScreen> createState() => _AskIQScreenState();
}

class _AskIQScreenState extends State<AskIQScreen> {
  final _controller    = TextEditingController();
  final _scrollCtrl    = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  final _welcomeMsg = const _ChatMessage(
    text: 'Hello! I\'m AskIQ — your AI fact-based research assistant. '
          'Ask me anything about news, science, politics, health, or any claim you want verified. '
          'I only cite verifiable information.',
    isUser: false,
  );

  @override
  void initState() {
    super.initState();
    _messages.add(_welcomeMsg);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await GeminiService.instance.askQuestion(text);
      final answer       = response['answer']       as String? ?? 'No response.';
      final sources      = List<String>.from(response['sources']      ?? []);
      final relatedFacts = List<String>.from(response['relatedFacts'] ?? []);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text:        answer,
            isUser:      false,
            sources:     sources,
            relatedFacts:relatedFacts,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(const _ChatMessage(
            text:   'Could not process your question. Please try again.',
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.askIQTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
            tooltip: 'Clear chat',
            onPressed: () {
              if (!mounted) return;
              setState(() {
                _messages
                  ..clear()
                  ..add(_welcomeMsg);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[i];
                return ChatBubble(
                  text: msg.text,
                  isUser: msg.isUser,
                  sources: msg.sources,
                  index: i,
                );
              },
            ),
          ),
          _buildInputBar(),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:     _controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText:       AppStrings.askHint,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines:       3,
              minLines:       1,
              textInputAction:TextInputAction.send,
              onSubmitted:    (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color:  _isLoading
                    ? AppColors.textMuted
                    : AppColors.accent,
                shape:  BoxShape.circle,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color:       AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _AiAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color:        AppColors.bgCard,
              borderRadius: BorderRadius.only(
                topRight:    Radius.circular(16),
                bottomLeft:  Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: List.generate(3, (i) => Container(
                width:  8, height: 8,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat())
                .fadeOut(delay: (i * 200).ms, duration: 400.ms)
                .then().fadeIn(duration: 400.ms)),
            ),
          ),
        ],
      ),
    );
  }
}



class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width:  28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgCard,
      ),
      child: const Icon(Icons.lens, color: AppColors.accent, size: 16),
    );
  }
}
