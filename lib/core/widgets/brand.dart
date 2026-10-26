import 'package:flutter/material.dart';

import '../assets/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// "LungSense Pro" wordmark as text ("Pro" in supportingGreen), as drawn in
/// Main.dc.html and AccountStatus.dc.html.
class LsWordmark extends StatelessWidget {
  const LsWordmark({super.key, this.style});
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? LsText.brand;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'LungSense '),
          TextSpan(
            text: 'Pro',
            style: base.copyWith(color: AppColors.supportingGreen),
          ),
        ],
      ),
      style: base,
      semanticsLabel: 'LungSense Pro',
    );
  }
}

/// "Powered by DigiBiomics" footer using the supplied logo.
class PoweredByDigiBiomics extends StatelessWidget {
  const PoweredByDigiBiomics({super.key, this.logoHeight = 22});
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Powered by DigiBiomics',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'POWERED BY',
            style: LsText.footnote.copyWith(fontSize: 11, letterSpacing: 0.9),
          ),
          const SizedBox(height: 6),
          Image.asset(
            AppAssets.digibiomicsLogo,
            height: logoHeight,
            width: logoHeight * AppAssets.digibiomicsAspect,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
