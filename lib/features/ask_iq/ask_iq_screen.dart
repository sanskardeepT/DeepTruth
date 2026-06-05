import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/gemini_service.dart';
import '../../widgets/ad_banner_widget.dart';

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
            onPressed: () => setState(() {
              _messages
                ..clear()
                ..add(_welcomeMsg);
            }),
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
                return _ChatBubble(msg: _messages[i], index: i);
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

class _ChatBubble extends StatelessWidget {
  final _ChatMessage msg;
  final int index;

  const _ChatBubble({required this.msg, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: msg.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: msg.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!msg.isUser) ...[
                _AiAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(msg.isUser ? 16 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: msg.isUser
                          ? AppColors.accent.withValues(alpha: 0.3)
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      color:   AppColors.textPrimary,
                      fontSize:13,
                      height:  1.5,
                    ),
                  ),
                ),
              ),
              if (msg.isUser) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 16),
                ),
              ],
            ],
          ),
          // Sources
          if (!msg.isUser && msg.sources.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Wrap(
                spacing:    4,
                runSpacing: 4,
                children: msg.sources.take(3).map((s) => _SourceChip(source: s)).toList(),
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: (index * 30).ms).fadeIn().slideY(begin: 0.1);
  }
}

class _SourceChip extends StatelessWidget {
  final String source;
  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final isUrl = source.startsWith('http');
    return GestureDetector(
      onTap: isUrl ? () async {
        final uri = Uri.tryParse(source);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_rounded, color: AppColors.accent, size: 10),
            const SizedBox(width: 3),
            Text(
              source.length > 40 ? '${source.substring(0, 40)}…' : source,
              style: const TextStyle(color: AppColors.accent, fontSize: 10),
            ),
          ],
        ),
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
