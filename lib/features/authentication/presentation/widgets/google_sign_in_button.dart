import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_button.dart';

/// "Continue with Google" from Login/RoleChoice. Google OAuth is not enabled
/// on the server, so the entry point is disabled and says so. The flow
/// (PKCE, browser session, token exchange) is not wired until the server
/// is configured; see docs/KNOWN_ISSUES.md KI-03. `GOOGLE_SIGN_IN_ENABLED`
/// is reserved for that milestone.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LsButton(
          label: 'Continue with Google',
          variant: LsButtonVariant.secondary,
          onPressed: null,
          icon: Text(
            'G',
            style: LsText.button.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Google sign-in isn\'t available yet.',
          textAlign: TextAlign.center,
          style: LsText.helper,
        ),
      ],
    );
  }
}
