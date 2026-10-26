import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// Auth-screen layout from the designs: 56px header with a 44px back button
/// and optional trailing text, a scrollable body with the 24px gutter, and
/// a fixed bottom action area that rises with the keyboard.
class LsScreen extends StatelessWidget {
  const LsScreen({
    super.key,
    required this.body,
    this.bottom,
    this.onBack,
    this.backLabel = 'Back',
    this.headerTrailing,
    this.headerLeading,
    this.bottomDivider = false,
  });

  final Widget body;
  final Widget? bottom;

  /// Null hides the back button.
  final VoidCallback? onBack;
  final String backLabel;
  final Widget? headerTrailing;

  /// Replaces the back button (e.g. the wordmark on AccountStatus).
  final Widget? headerLeading;
  final bool bottomDivider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: LsSize.headerHeight,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 16),
                child: Row(
                  children: [
                    if (headerLeading != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: headerLeading,
                      )
                    else if (onBack != null)
                      IconButton(
                        tooltip: backLabel,
                        onPressed: onBack,
                        icon: const Icon(Icons.chevron_left, size: 28),
                        color: AppColors.text,
                        constraints: const BoxConstraints.tightFor(
                          width: LsSize.minTouch,
                          height: LsSize.minTouch,
                        ),
                      ),
                    const Spacer(),
                    ?headerTrailing,
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  LsSpace.authGutter,
                  4,
                  LsSpace.authGutter,
                  LsSpace.md,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: body,
              ),
            ),
            if (bottom != null)
              Container(
                decoration: bottomDivider
                    ? const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      )
                    : null,
                padding: const EdgeInsets.fromLTRB(
                  LsSpace.authGutter,
                  LsSpace.sm,
                  LsSpace.authGutter,
                  LsSpace.lg,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}
