import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'ls_button.dart';

/// Opens [child] as a bottom sheet with the 16px top radius (States.dc.html).
Future<T?> showLsSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LsRadius.sheet),
        ),
      ),
      builder: (_) => child,
    );

/// Result of [LsConfirmSheet]: confirmed, with the typed reason if any.
class LsConfirmResult {
  const LsConfirmResult([this.reason]);
  final String? reason;
}

/// Confirmation sheet (Review "Submit this session?", admin suspend).
/// With [reasonLabel] it shows a text field; [reasonRequired] keeps the
/// confirm button disabled until something is typed.
class LsConfirmSheet extends StatefulWidget {
  const LsConfirmSheet({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.body,
    this.variant = LsButtonVariant.primary,
    this.reasonLabel,
    this.reasonHint,
    this.reasonRequired = false,
    this.reasonMaxLength,
    this.confirmKey,
  });

  final String title;
  final String? body;
  final String confirmLabel;
  final LsButtonVariant variant;
  final String? reasonLabel;
  final String? reasonHint;
  final bool reasonRequired;
  final int? reasonMaxLength;
  final Key? confirmKey;

  @override
  State<LsConfirmSheet> createState() => _LsConfirmSheetState();
}

class _LsConfirmSheetState extends State<LsConfirmSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _reason.text.trim();
    final ok = !widget.reasonRequired || text.isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LsSpace.authGutter,
        12,
        LsSpace.authGutter,
        LsSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: LsSpace.md),
          Text(widget.title, style: LsText.section),
          if (widget.body != null) ...[
            const SizedBox(height: LsSpace.xs),
            Text(
              widget.body!,
              style: LsText.bannerBody.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (widget.reasonLabel != null) ...[
            const SizedBox(height: LsSpace.md),
            Text(widget.reasonLabel!, style: LsText.label),
            const SizedBox(height: 6),
            TextField(
              key: const Key('confirm_reason'),
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              maxLength: widget.reasonMaxLength,
              style: LsText.body,
              decoration: InputDecoration(hintText: widget.reasonHint),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: LsSpace.md),
          Row(
            children: [
              Expanded(
                child: LsButton(
                  label: 'Cancel',
                  variant: LsButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: LsSpace.sm),
              Expanded(
                child: LsButton(
                  key: widget.confirmKey ?? const Key('confirm_ok'),
                  label: widget.confirmLabel,
                  variant: widget.variant,
                  onPressed: ok
                      ? () => Navigator.of(context)
                            .pop(LsConfirmResult(text.isEmpty ? null : text))
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Short confirmation message (LsToast in the handoff), shown only after
/// the server confirmed the action.
void showLsToast(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: LsText.bannerBody.copyWith(color: AppColors.surface),
        ),
        backgroundColor: AppColors.text,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LsRadius.control),
        ),
      ),
    );
}
