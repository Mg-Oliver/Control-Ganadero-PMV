import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final bool showLabel;
  final double? minimumInputHeight;
  final String? hint;
  final String? helperText;
  final String? suffixText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? headerTrailing;
  final bool readOnly;
  final bool enabled;
  final bool isRequired;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.label,
    this.showLabel = true,
    this.minimumInputHeight,
    this.hint,
    this.helperText,
    this.suffixText,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.headerTrailing,
    this.readOnly = false,
    this.enabled = true,
    this.isRequired = false,
    this.onTap,
  });

  factory CustomTextField.numeric({
    Key? key,
    required String label,
    bool showLabel = true,
    double? minimumInputHeight,
    String? hint,
    String? helperText,
    String? suffixText,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    Widget? prefixIcon,
    bool isRequired = false,
    bool allowDecimals = true,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      label: label,
      showLabel: showLabel,
      minimumInputHeight: minimumInputHeight,
      hint: hint,
      helperText: helperText,
      suffixText: suffixText,
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      onChanged: onChanged,
      prefixIcon: prefixIcon,
      isRequired: isRequired,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimals),
      inputFormatters: [
        if (allowDecimals)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            children: [
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      if (isRequired)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ?headerTrailing,
            ],
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            constraints: minimumInputHeight == null
                ? null
                : BoxConstraints(minHeight: minimumInputHeight!),
            // Mantiene el nombre accesible al ocultar el encabezado de campos agrupados.
            hintText: hint ?? (showLabel ? null : label),
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
            helperText: helperText,
            suffixText: suffixText,
            suffixStyle: showLabel ? null : const TextStyle(fontSize: 10),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: (!enabled || readOnly)
                ? const Color(0xFFF3F4F6)
                : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: showLabel ? 14 : 8,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
