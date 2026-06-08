import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/osint_result.dart';

class OsintInputPanel extends StatefulWidget {
  final OsintQueryType type;
  final void Function(String) onSearch;

  const OsintInputPanel({
    super.key,
    required this.type,
    required this.onSearch,
  });

  @override
  State<OsintInputPanel> createState() => _OsintInputPanelState();
}

class _OsintInputPanelState extends State<OsintInputPanel> {
  final _controller = TextEditingController();
  String? _selectedImagePath;

  @override
  void didUpdateWidget(OsintInputPanel old) {
    super.didUpdateWidget(old);
    if (old.type != widget.type) {
      _controller.clear();
      setState(() {
        _selectedImagePath = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  String get _hint {
    switch (widget.type) {
      case OsintQueryType.email:    return 'Enter email address…';
      case OsintQueryType.phone:    return 'Enter phone number (with country code)…';
      case OsintQueryType.username: return 'Enter username (without @)…';
      case OsintQueryType.ip:       return 'Enter IP address (e.g. 8.8.8.8)…';
      case OsintQueryType.website:  return 'Enter domain (e.g. example.com)…';
      default:                      return 'Enter query…';
    }
  }

  String get _buttonLabel {
    switch (widget.type) {
      case OsintQueryType.email:    return 'Check Breaches';
      case OsintQueryType.phone:    return 'Lookup Phone';
      case OsintQueryType.username: return 'Find Profiles';
      case OsintQueryType.ip:       return 'Lookup IP';
      case OsintQueryType.website:  return 'WHOIS Lookup';
      default:                      return 'Search';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == OsintQueryType.image) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedImagePath == null)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_search_rounded, color: AppColors.textMuted, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Tap to upload screenshot or image',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Container(
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
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Image for Forensics',
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
                      if (mounted) {
                        setState(() {
                          _selectedImagePath = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedImagePath == null
                  ? null
                  : () => widget.onSearch(_selectedImagePath!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Analyze Image Metadata',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller:  _controller,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(hintText: _hint),
          textInputAction: TextInputAction.search,
          onSubmitted: widget.onSearch,
          keyboardType: widget.type == OsintQueryType.phone
              ? TextInputType.phone
              : widget.type == OsintQueryType.email
                  ? TextInputType.emailAddress
                  : TextInputType.url,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width:  double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => widget.onSearch(_controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
