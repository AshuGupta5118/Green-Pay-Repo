import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String? placeholder;
  final String? label;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;

  const CustomTextField({
    super.key,
    this.placeholder,
    this.label,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.prefix,
    this.suffix,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: widget.enabled
                ? CupertinoColors.tertiarySystemBackground
                : CupertinoColors.systemGrey6,
            borderRadius: AppTheme.standardBorderRadius,
            border: Border.all(
              color: _getBorderColor(),
              width: 1,
            ),
          ),
          child: CupertinoTextField(
            controller: widget.controller,
            focusNode: _focusNode,
            placeholder: widget.placeholder,
            placeholderStyle: const TextStyle(
              color: CupertinoColors.placeholderText,
              fontSize: 17,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: null,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            prefix: widget.prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: widget.prefix,
                  )
                : null,
            suffix: widget.suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: widget.suffix,
                  )
                : null,
            style: const TextStyle(
              fontSize: 17,
            ),
            cursorColor: AppTheme.primaryColor,
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.errorColor,
            ),
          ),
        ],
      ],
    );
  }

  Color _getBorderColor() {
    if (widget.errorText != null) {
      return AppTheme.errorColor;
    }
    if (_isFocused) {
      return AppTheme.primaryColor;
    }
    return CupertinoColors.systemGrey5;
  }
}
