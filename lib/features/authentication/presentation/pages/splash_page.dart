import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../cubit/session_cubit.dart';

/// Launch screen while the stored session is validated. Mirrors
/// "LungSense Pro Medical App Splash Screen.png": stacked logo centred,
/// "Powered by DigiBiomics" at the bottom.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LsSpace.authGutter),
          child: BlocBuilder<SessionCubit, SessionState>(
            builder: (context, state) {
              final failed = state is SessionRestoreFailed ? state : null;
              return Column(
                children: [
                  const Spacer(flex: 3),
                  LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth.clamp(0, 300).toDouble();
                      return Image.asset(
                        AppAssets.logoStacked,
                        width: w,
                        height: w / AppAssets.logoStackedAspect,
                        fit: BoxFit.contain,
                        semanticLabel:
                            'LungSense Pro. Clinical data collection.',
                      );
                    },
                  ),
                  const SizedBox(height: LsSpace.xl),
                  if (failed == null)
                    const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        semanticsLabel: 'Checking your session',
                      ),
                    )
                  else ...[
                    LsBanner(
                      tone: failed.failure.isConnectivity
                          ? LsBannerTone.warning
                          : LsBannerTone.dark,
                      title: failed.failure.isConnectivity
                          ? 'Can\'t reach LungSense Pro.'
                          : 'Server-side problem.',
                      body: failed.failure.isConnectivity
                          ? 'Check your connection and try again.'
                          : _serverBody(failed.failure),
                    ),
                    const SizedBox(height: LsSpace.md),
                    LsButton(
                      label: 'Try again',
                      onPressed: () => context.read<SessionCubit>().restore(),
                    ),
                  ],
                  const Spacer(flex: 4),
                  const PoweredByDigiBiomics(),
                  const SizedBox(height: LsSpace.lg),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _serverBody(Failure f) => f.kind == FailureKind.rateLimited
      ? 'Too many attempts. Please wait a few minutes and try again.'
      : 'We couldn\'t restore your session. Please try again shortly.';
}
