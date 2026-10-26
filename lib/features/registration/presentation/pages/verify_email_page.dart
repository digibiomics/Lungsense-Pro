import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_screen.dart';
import '../cubit/resend_confirmation_cubit.dart';

/// 06 Check your email (VerifyEmail.dc.html). Shown after a 201 from
/// `/auth/register`. The confirmation link itself is handled by the backend
/// (no app deep link is documented), so the user returns and signs in.
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key, required this.email, required this.doctor});

  final String email;
  final bool doctor;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResendConfirmationCubit, ResendState>(
      builder: (context, state) {
        return LsScreen(
          onBack: () => context.go(Routes.login),
          backLabel: 'Back to sign in',
          body: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: LsTint.iconDisc,
                      borderRadius: BorderRadius.circular(LsRadius.panel),
                    ),
                    child: const Icon(
                      Icons.mail_outline,
                      color: AppColors.text,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: LsSpace.lg),
                Semantics(
                  header: true,
                  child: Text('Check your email', style: LsText.pageTitle),
                ),
                const SizedBox(height: LsSpace.xs),
                Text(
                  'We\'ve sent a confirmation link to',
                  style: LsText.subtitle,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: LsText.subtitle.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                for (final (i, step) in const [
                  'Open the email from LungSense Pro.',
                  'Tap the confirmation link.',
                  'Come back here and sign in.',
                ].indexed) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _NumberedStep(number: i + 1, text: step),
                ],
                if (doctor) ...[
                  const SizedBox(height: 20),
                  LsNote(
                    color: AppColors.warning.withValues(alpha: .18),
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Doctor accounts',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text:
                                ' also need approval from the research team '
                                'before you can collect data.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: LsSpace.sm),
                LsNote(
                  bordered: true,
                  child: Text(
                    'Not there after a few minutes? Check your spam or junk '
                    'folder.',
                    style: LsText.bannerBody.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (state.sent) ...[
                  const SizedBox(height: LsSpace.sm),
                  const LsBanner(
                    tone: LsBannerTone.success,
                    title: 'Request received.',
                    body:
                        'If this address still needs confirming, a new email '
                        'is on its way.',
                  ),
                ],
                if (state.failure != null) ...[
                  const SizedBox(height: LsSpace.sm),
                  Builder(
                    builder: (_) {
                      final copy = FailureMessages.generic(state.failure!);
                      return LsBanner(
                        tone: LsBannerTone.warning,
                        title: copy.title,
                        body: copy.body,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LsButton(
                label: 'Back to sign in',
                onPressed: () => context.go(Routes.login),
              ),
              const SizedBox(height: LsSpace.sm),
              LsButton(
                key: const Key('verify_resend'),
                variant: LsButtonVariant.secondary,
                label: state.cooldown > 0
                    ? 'Resend available in ${state.cooldown} s'
                    : 'Resend email',
                loadingLabel: 'Sending…',
                loading: state.sending,
                onPressed: state.cooldown > 0
                    ? null
                    : () =>
                          context.read<ResendConfirmationCubit>().resend(email),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            '$number',
            style: LsText.helper.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: LsSpace.sm),
        Expanded(child: Text(text, style: LsText.bodySmall)),
      ],
    );
  }
}
