import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../core/widgets/ls_button.dart';

/// 01 Welcome (Main.dc.html).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              LsSpace.authGutter,
              0,
              LsSpace.authGutter,
              28,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 28,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    const SizedBox(height: LsSpace.lg),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        AppAssets.appIconTile,
                        width: 72,
                        height: 72,
                        semanticLabel: 'LungSense Pro logo',
                      ),
                    ),
                    const SizedBox(height: 28),
                    const LsWordmark(),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        'Collect cough, breathing and symptom data for '
                        'respiratory research.',
                        style: LsText.lead,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _Feature(
                      tint: LsTint.featurePrimary,
                      icon: Icons.mic_none_outlined,
                      text: 'Guided cough and breathing recordings',
                    ),
                    const SizedBox(height: LsSpace.sm),
                    _Feature(
                      tint: LsTint.featureSecondary,
                      icon: Icons.assignment_turned_in_outlined,
                      text: 'Quick symptom severity log',
                    ),
                    const SizedBox(height: LsSpace.sm),
                    _Feature(
                      tint: LsTint.featureAccent,
                      icon: Icons.lock_outline,
                      text: 'Private, encrypted research storage',
                    ),
                    const Spacer(),
                    const SizedBox(height: LsSpace.lg),
                    LsButton(
                      label: 'Sign in',
                      onPressed: () => context.push(Routes.login),
                    ),
                    const SizedBox(height: 10),
                    LsButton(
                      label: 'Create an account',
                      variant: LsButtonVariant.secondary,
                      onPressed: () => context.push(Routes.signUp),
                    ),
                    const SizedBox(height: LsSpace.md),
                    Text(
                      'Pro accounts are separate from LungSense Wellness.\n'
                      'For research data collection only. Not a diagnostic '
                      'tool.',
                      textAlign: TextAlign.center,
                      style: LsText.footnote,
                    ),
                    const SizedBox(height: LsSpace.sm),
                    const PoweredByDigiBiomics(logoHeight: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.tint, required this.icon, required this.text});
  final Color tint;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(LsRadius.small),
          ),
          child: Icon(icon, size: 18, color: AppColors.text),
        ),
        const SizedBox(width: LsSpace.sm),
        Expanded(
          child: Text(text, style: LsText.bodySmall.copyWith(height: 21 / 15)),
        ),
      ],
    );
  }
}
