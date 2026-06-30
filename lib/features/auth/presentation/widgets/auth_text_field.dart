import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Labeled, rounded text field used across the auth screens.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffix,
      ),
    );
  }
}
