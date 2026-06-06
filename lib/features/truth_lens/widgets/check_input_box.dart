import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class CheckInputBox extends StatefulWidget {
  final void Function(String) onSubmit;
  final TextEditingController? controller;

  const CheckInputBox({
    super.key,
    required this.onSubmit,
    this.controller,
  });

  @override
  State<CheckInputBox> createState() => _CheckInputBoxState();
}

class _CheckInputBoxState extends State<CheckInputBox> {
  late final TextEditingController _controller;
  final _focusNode  = FocusNode();
  bool _hasText = false;
  bool _isLocalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isLocalController = false;
    } else {
      _controller = TextEditingController();
      _isLocalController = true;
    }
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      if (mounted) setState(() => _hasText = has);
    }
  }

  @override
  void didUpdateWidget(CheckInputBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onControllerChange);
      if (_isLocalController) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _isLocalController = false;
      } else {
        _controller = TextEditingController();
        _isLocalController = true;
      }
      _hasText = _controller.text.trim().isNotEmpty;
      _controller.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    if (_isLocalController) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _focusNode.unfocus();
    widget.onSubmit(text);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color:        AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppColors.accent
                  : AppColors.divider,
            ),
            boxShadow: _focusNode.hasFocus
                ? [BoxShadow(
                    color:      AppColors.accent.withValues(alpha: 0.1),
                    blurRadius: 12,
                  )]
                : null,
          ),
          child: Column(
            children: [
              TextField(
                controller:  _controller,
                focusNode:   _focusNode,
                maxLines:    6,
                minLines:    4,
                style: const TextStyle(
                  color:   AppColors.textPrimary,
                  fontSize:14,
                  height:  1.5,
                ),
                decoration: const InputDecoration(
                  border:          InputBorder.none,
                  enabledBorder:   InputBorder.none,
                  focusedBorder:   InputBorder.none,
                  hintText:        AppStrings.pasteHint,
                  contentPadding:  EdgeInsets.all(16),
                ),
                textInputAction: TextInputAction.newline,
                onChanged: (_) {
                  if (mounted) setState(() {});
                },
              ),
              Container(
                height: 1,
                color:  AppColors.divider,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _paste,
                      icon:  const Icon(Icons.content_paste_rounded, size: 16),
                      label: const Text('Paste'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    if (_hasText)
                      TextButton.icon(
                        onPressed: () {
                          _controller.clear();
                          setState(() => _hasText = false);
                        },
                        icon:  const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '${_controller.text.length} chars',
                      style: const TextStyle(
                        color:   AppColors.textMuted,
                        fontSize:11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedOpacity(
          opacity: _hasText ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width:  double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _hasText ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.policy_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    AppStrings.analyzeBtn,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:   16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
