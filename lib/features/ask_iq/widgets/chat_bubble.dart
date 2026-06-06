import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:clipboard/clipboard.dart';
import '../../../core/constants/app_colors.dart';
import 'source_chip.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final List<String> sources;
  final int index;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.sources,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const _AiAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () async {
                    await FlutterClipboard.copy(text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isUser
                            ? AppColors.accent.withValues(alpha: 0.3)
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.person_rounded, color: AppColors.primary, size: 16),
                ),
              ],
            ],
          ),
          // Sources
          if (!isUser && sources.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: sources.take(3).map((s) => SourceChip(source: s)).toList(),
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: (index * 30).ms).fadeIn().slideY(begin: 0.1);
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgCard,
      ),
      child: const Icon(Icons.lens, color: AppColors.accent, size: 16),
    );
  }
}
