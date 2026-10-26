import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'ls_button.dart';
import 'ls_screen.dart';

/// Temporary route target for flows scheduled in a later milestone, so the
/// Welcome and Login links are wired without pretending the flow exists.
/// Replaced screen-by-screen as milestones land (see docs/ROADMAP.md).
class UpcomingPage extends StatelessWidget {
  const UpcomingPage({
    super.key,
    required this.title,
    required this.message,
    required this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LsScreen(
      onBack: onBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LsText.authTitle),
          const SizedBox(height: 6),
          Text(message, style: LsText.subtitle),
        ],
      ),
      bottom: LsButton(
        label: 'Go back',
        variant: LsButtonVariant.secondary,
        onPressed: onBack,
      ),
    );
  }
}
