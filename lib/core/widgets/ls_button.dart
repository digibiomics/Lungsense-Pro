import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

enum LsButtonVariant { primary, secondary, text, submitDark, destructive }

/// Button from Components.dc.html. Primary is green with dark text; while
/// [loading] it shows the 55% tint and [loadingLabel] and ignores taps.
class LsButton extends StatelessWidget {
  const LsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = LsButtonVariant.primary,
    this.loading = false,
    this.loadingLabel,
    this.icon,
    this.height = LsSize.button,
  });

  final String label;
  final VoidCallback? onPressed;
  final LsButtonVariant variant;
  final bool loading;
  final String? loadingLabel;
  final Widget? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      LsButtonVariant.primary => (
        loading
            ? LsTint.loadingButton
            : enabled
            ? AppColors.primary
            : AppColors.border,
        enabled || loading ? AppColors.text : AppColors.textSecondary,
        BorderSide.none,
      ),
      LsButtonVariant.secondary => (
        enabled ? AppColors.surface : AppColors.background,
        enabled ? AppColors.text : AppColors.textSecondary,
        const BorderSide(color: AppColors.border),
      ),
      LsButtonVariant.text => (
        Colors.transparent,
        AppColors.supportingGreen,
        BorderSide.none,
      ),
      LsButtonVariant.submitDark => (
        enabled || loading ? AppColors.text : AppColors.border,
        enabled || loading ? AppColors.surface : AppColors.textSecondary,
        BorderSide.none,
      ),
      LsButtonVariant.destructive => (
        enabled ? AppColors.error : AppColors.border,
        enabled ? AppColors.surface : AppColors.textSecondary,
        BorderSide.none,
      ),
    };

    final text = loading ? (loadingLabel ?? label) : label;
    return Semantics(
      button: true,
      enabled: enabled,
      label: text,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg,
            disabledForegroundColor: fg,
            minimumSize: const Size(LsSize.minTouch, LsSize.minTouch),
            padding: const EdgeInsets.symmetric(horizontal: LsSpace.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LsRadius.control),
              side: side,
            ),
            textStyle: LsText.button,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) ...[
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                ),
                const SizedBox(width: 10),
              ] else if (icon != null) ...[
                icon!,
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: LsText.button.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
