import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:conecta_utsh/helpers/style.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.hint,
    required this.validator,
    this.label,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
    this.suffixIcon,
    this.inputFormatters,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?) validator;
  final String? label;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: Style.getTextStyle(color: Style.getTextColor(), fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Style.getHeaderThree(
          color: Style.getTextColor(),
          fontSize: 10,
        ),
        hintText: hint,
        hintStyle: Style.getHintStyle(
          color: Style.getObscureTextColor(),
          fontSize: 12,
        ),
        filled: true,
        fillColor: Style.getCardColor(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Style.getSubtleColor(), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Style.getPrimaryColor(), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Style.getErrorColor()),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Style.getErrorColor(), width: 1.5),
        ),
      ),
    );
  }
}
