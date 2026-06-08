import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class CheckInputBox extends StatefulWidget {
  final void Function(String text, String? imagePath) onSubmit;
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
  String? _selectedImagePath;

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
    var text = _controller.text.trim();
    if (text.isEmpty && _selectedImagePath != null) {
      text = "Verification analysis of the attached image claim.";
    }
    if (text.isEmpty) return;
    _focusNode.unfocus();
    widget.onSubmit(text, _selectedImagePath);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (mounted) {
          setState(() {
            _selectedImagePath = image.path;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  bool get _canSubmit => _hasText || _selectedImagePath != null;

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
              if (_selectedImagePath != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImagePath!),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Attached Image',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedImagePath!.split(Platform.pathSeparator).last,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                        onPressed: () {
                          if (mounted) setState(() => _selectedImagePath = null);
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon:  const Icon(Icons.image_search_rounded, size: 16),
                      label: Text(_selectedImagePath == null ? 'Screenshot' : 'Change Image'),
                      style: TextButton.styleFrom(
                        foregroundColor: _selectedImagePath == null ? AppColors.textMuted : AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          _controller.clear();
                          if (mounted) setState(() => _hasText = false);
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
          opacity: _canSubmit ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width:  double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
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
