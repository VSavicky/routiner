import 'package:flutter/material.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/core/constants/app_fonts.dart';

class AuthInputField extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final bool isValid;
  final VoidCallback? onClear;
  final bool autoFocus;

  const AuthInputField({
    super.key,
    required this.title,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.isValid = true,
    this.onClear,
    this.autoFocus = false,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
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

  bool get _isValid {
    if (!widget.isValid) return false;
    if (widget.controller.text.isEmpty) return false; 
    return widget.isValid; 
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
          obscureText: widget.obscureText,
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
            suffixIcon: widget.onClear != null && widget.controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: widget.onClear,
                    child: Icon(
                      Icons.close,
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
              widget.controller.text.contains('@') 
                  ? 'Please enter a valid email address'
                  : 'Please enter a valid ${widget.title.toLowerCase()}',
              style: AppFonts.bodyAlternative.copyWith(
                color: AppColors.red,
              ),
            ),
          ),
      ],
    );
  }
}
