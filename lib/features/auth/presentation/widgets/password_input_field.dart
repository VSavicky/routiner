import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';

class PasswordInputField extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final bool isValid;
  final VoidCallback? onClear;
  final bool autoFocus;

  const PasswordInputField({
    super.key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.isValid = true,
    this.onClear,
    this.autoFocus = false,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  bool get _isValid {
    if (!widget.isValid) return false;
    if (widget.controller.text.isEmpty) return false; 
    return widget.isValid && widget.controller.text.length >= 8; 
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppFonts.bodyTitleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          autofocus: widget.autoFocus,
          style: AppFonts.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppFonts.bodyMedium.copyWith(
              color: AppColors.black40,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _isValid ? AppColors.green : (widget.controller.text.isEmpty ? AppColors.black20 : AppColors.red),
                width: 1,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _isValid ? AppColors.blue100 : (widget.controller.text.isEmpty ? AppColors.black20 : AppColors.red),
                width: 1,
              ),
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: _togglePasswordVisibility,
                    child: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: AppColors.black40,
                    ),
                  )
                : null,
          ),
        ),
        if (!_isValid && widget.controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Password must be at least 8 characters',
              style: AppFonts.bodyAlternative.copyWith(
                color: AppColors.red,
              ),
            ),
          ),
      ],
    );
  }
}
