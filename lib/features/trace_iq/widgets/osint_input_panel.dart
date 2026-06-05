import 'package:flutter/material.dart';
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

  @override
  void didUpdateWidget(OsintInputPanel old) {
    super.didUpdateWidget(old);
    if (old.type != widget.type) _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
