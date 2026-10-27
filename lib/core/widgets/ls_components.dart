import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// Status pill from Components.dc.html (dot + label on a tint).
enum LsPillTone { pending, success, error, neutral }

class LsStatusPill extends StatelessWidget {
  const LsStatusPill({super.key, required this.label, required this.tone});
  final String label;
  final LsPillTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color dot) = switch (tone) {
      LsPillTone.pending => (LsTint.draftPill, AppColors.warning),
      LsPillTone.success => (LsTint.completedPill, AppColors.success),
      LsPillTone.error => (LsTint.errorBg, AppColors.error),
      LsPillTone.neutral => (AppColors.border, AppColors.textSecondary),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: LsText.pill,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round initials avatar (accent tint, as in Dashboard/Profile).
class LsAvatar extends StatelessWidget {
  const LsAvatar({super.key, required this.name, this.size = 44});
  final String name;
  final double size;

  static String initialsOf(String name) {
    final parts = name
        .replaceAll(RegExp(r'^(dr\.?\s+)', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: .3),
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: LsText.listTitle.copyWith(fontSize: size * 15 / 44),
        semanticsLabel: '',
      ),
    );
  }
}

/// Icon + title + body + optional action (States.dc.html empty state).
class LsEmptyState extends StatelessWidget {
  const LsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(LsRadius.panel),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: LsTint.iconDisc,
              borderRadius: BorderRadius.circular(LsRadius.panel),
            ),
            child: Icon(icon, color: AppColors.text, size: 26),
          ),
          const SizedBox(height: LsSpace.md),
          Text(title, style: LsText.section, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(body, style: LsText.helper, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: LsSpace.md), action!],
        ],
      ),
    );
  }
}

/// Bordered white panel with rows separated by 1px dividers.
class LsPanel extends StatelessWidget {
  const LsPanel({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Material (not a coloured DecoratedBox) so tappable rows show ink.
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(LsRadius.panel),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Label/value row used in Profile and AdminReview `<dl>` lists.
class LsKeyValueRow extends StatelessWidget {
  const LsKeyValueRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Long labels (symptom names) wrap instead of overflowing.
          Flexible(
            child: Text(
              label,
              style: LsText.label.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: LsSpace.sm),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: LsText.label),
          ),
        ],
      ),
    );
  }
}

/// Tinted note panel (VerifyEmail doctor note, info boxes).
class LsNote extends StatelessWidget {
  const LsNote({
    super.key,
    required this.child,
    this.color,
    this.bordered = false,
  });
  final Widget child;
  final Color? color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        border: bordered ? Border.all(color: AppColors.border) : null,
        borderRadius: BorderRadius.circular(LsRadius.control),
      ),
      child: DefaultTextStyle.merge(style: LsText.bannerBody, child: child),
    );
  }
}

/// Consent checkbox row (Register.dc.html).
class LsCheckboxTile extends StatelessWidget {
  const LsCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      container: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(LsRadius.control),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(LsRadius.control),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : AppColors.surface,
                  border: Border.all(
                    color: value ? AppColors.primary : AppColors.textSecondary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(LsRadius.checkbox),
                ),
                child: value
                    ? const Icon(Icons.check, size: 16, color: AppColors.text)
                    : null,
              ),
              const SizedBox(width: LsSpace.sm),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: LsText.bannerBody,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable role card (RoleChoice.dc.html).
class LsChoiceCard extends StatelessWidget {
  const LsChoiceCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.iconTint,
    required this.title,
    required this.body,
    this.badge,
  });

  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconTint;
  final String title;
  final String body;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? LsTint.selectedCard : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LsRadius.panel),
          side: BorderSide(
            color: selected ? AppColors.supportingGreen : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LsRadius.panel),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconTint,
                    borderRadius: BorderRadius.circular(LsRadius.control),
                  ),
                  child: Icon(icon, color: AppColors.text),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: LsText.section),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: LsText.bannerBody.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (badge != null) ...[const SizedBox(height: 8), badge!],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.supportingGreen
                          : AppColors.textSecondary,
                      width: selected ? 2 : 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.supportingGreen,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Step 2 of 3 · Doctor" header label.
class LsStepLabel extends StatelessWidget {
  const LsStepLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: LsText.helper.copyWith(fontWeight: FontWeight.w600));
}

/// Green text link with a 44px touch target.
class LsLinkButton extends StatelessWidget {
  const LsLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
  });
  final String label;
  final VoidCallback? onPressed;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.supportingGreen,
        minimumSize: const Size(LsSize.minTouch, LsSize.minTouch),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        textStyle:
            style ?? LsText.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
