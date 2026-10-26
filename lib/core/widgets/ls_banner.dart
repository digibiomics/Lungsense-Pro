import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

enum LsBannerTone { error, warning, success, info, dark }

/// Inline feedback banner (States.dc.html, Login error variants).
class LsBanner extends StatelessWidget {
  const LsBanner({
    super.key,
    required this.tone,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.actionLoading = false,
    this.trailing,
  });

  final LsBannerTone tone;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionLoading;

  /// Extra content under the text (e.g. link buttons).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = tone == LsBannerTone.dark;
    final (
      Color bg,
      Border? border,
      Color iconColor,
      IconData icon,
    ) = switch (tone) {
      LsBannerTone.error => (
        LsTint.errorBg,
        Border.all(color: LsTint.errorBorder),
        AppColors.error,
        Icons.error_outline,
      ),
      LsBannerTone.warning => (
        LsTint.cautionBg,
        Border.all(color: LsTint.cautionBorder),
        AppColors.text,
        Icons.error_outline,
      ),
      LsBannerTone.success => (
        LsTint.successBg,
        null,
        AppColors.text,
        Icons.check_circle_outline,
      ),
      LsBannerTone.info => (
        LsTint.iconDisc,
        null,
        AppColors.text,
        Icons.info_outline,
      ),
      LsBannerTone.dark => (
        AppColors.text,
        null,
        AppColors.surface,
        Icons.cloud_off_outlined,
      ),
    };
    final textColor = dark ? AppColors.surface : AppColors.text;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(LsRadius.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (body != null) TextSpan(text: ' $body'),
                      ],
                    ),
                    style: LsText.bannerBody.copyWith(color: textColor),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 4),
                    trailing!,
                  ],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: actionLoading ? null : onAction,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.text,
                          disabledForegroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(LsSize.minTouch, 36),
                          tapTargetSize: MaterialTapTargetSize.padded,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(LsRadius.small),
                          ),
                          textStyle: LsText.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(actionLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
