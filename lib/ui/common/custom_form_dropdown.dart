import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomFormDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final Widget? headerTrailing;
  final bool isRequired;
  final bool isLoading;
  final bool enabled;

  const CustomFormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
    this.prefixIcon,
    this.headerTrailing,
    this.isRequired = false,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.any((item) => item.value == value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: RichText(
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
        DropdownButtonFormField<T>(
          key: ValueKey(effectiveValue),
          initialValue: effectiveValue,
          items: items,
          onChanged: (enabled && !isLoading) ? onChanged : null,
          validator: validator,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          elevation: 2,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: isLoading ? 'Cargando opciones...' : hint,
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: (enabled && !isLoading)
                ? Colors.white
                : const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
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
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
