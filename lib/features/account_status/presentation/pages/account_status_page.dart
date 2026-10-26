import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_screen.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/cubit/session_cubit.dart';

enum _StepKind { done, current, failed, todo }

class _Step {
  const _Step(this.label, this.kind, this.status);
  final String label;
  final _StepKind kind;
  final String status;
}

class _Variant {
  const _Variant({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.steps,
    required this.footnote,
    this.contactSupport = false,
  });
  final IconData icon;
  final Color iconBg;
  final String title;
  final String body;
  final List<_Step> steps;
  final String footnote;
  final bool contactSupport;
}

/// 09 Account status (AccountStatus.dc.html). Shown for 403 account-status
/// codes and for profiles whose `account_status` is not `active`.
/// The session has already been cleared when this page is visible.
class AccountStatusPage extends StatelessWidget {
  const AccountStatusPage({super.key});

  static _Variant _variant(AccountRestricted r) {
    const verified = _Step('Email address', _StepKind.done, 'Verified');
    const profileDone = _Step('Doctor profile', _StepKind.done, 'Complete');
    return switch (r.status) {
      AccountStatus.pendingApproval => _Variant(
        icon: Icons.schedule,
        iconBg: LsTint.pendingDisc,
        title: 'Waiting for approval',
        body:
            'The research team is reviewing your doctor profile. You can '
            'start collecting data once it is approved.',
        steps: const [
          verified,
          profileDone,
          _Step('Research team approval', _StepKind.current, 'Under review'),
        ],
        footnote:
            'You stay signed out until approval. We\'ll email you when '
            'it\'s done.',
      ),
      AccountStatus.rejected => _Variant(
        icon: Icons.error_outline,
        iconBg: LsTint.errorDisc,
        title: 'Account not approved',
        body: r.message == null || r.message!.trim().isEmpty
            ? 'Your application was not approved.'
            : 'Your application was not approved. ${r.message}',
        steps: const [
          verified,
          profileDone,
          _Step('Research team approval', _StepKind.failed, 'Not approved'),
        ],
        footnote: 'If you think this is a mistake, please contact us.',
        contactSupport: true,
      ),
      AccountStatus.suspended || AccountStatus.deactivated => _Variant(
        icon: Icons.error_outline,
        iconBg: LsTint.errorDisc,
        title: 'Account not active',
        body:
            'This account has been suspended or deactivated by an '
            'administrator. Your submitted data is not affected.',
        steps: [
          verified,
          _Step(
            'Account access',
            _StepKind.failed,
            r.status == AccountStatus.suspended ? 'Suspended' : 'Deactivated',
          ),
        ],
        footnote: 'Only an administrator can reactivate the account.',
        contactSupport: true,
      ),
      _ => _Variant(
        icon: Icons.error_outline,
        iconBg: LsTint.errorDisc,
        title: 'Account not available',
        body:
            'This account can\'t be used in LungSense Pro right now. '
            'Please contact the research coordinator.',
        steps: const [
          _Step('Account access', _StepKind.failed, 'Not available'),
        ],
        footnote: 'For research data collection only. Not a diagnostic tool.',
        contactSupport: true,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SessionCubit>().state;
    final outcome = state is SessionResolved ? state.outcome : null;
    final restricted = outcome is AccountRestricted
        ? outcome
        : const AccountRestricted(AccountStatus.unknown);
    final v = _variant(restricted);
    final session = context.read<SessionCubit>();

    void close() => session.dismissRestriction();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: LsScreen(
        headerLeading: LsWordmark(
          style: LsText.listTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        headerTrailing: TextButton(
          onPressed: close,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(LsSize.minTouch, LsSize.minTouch),
            textStyle: LsText.label.copyWith(fontWeight: FontWeight.w600),
          ),
          child: const Text('Close'),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: LsSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: v.iconBg,
                  borderRadius: BorderRadius.circular(LsRadius.panel),
                ),
                child: Icon(v.icon, color: AppColors.text, size: 28),
              ),
              const SizedBox(height: LsSpace.lg),
              Semantics(
                header: true,
                child: Text(v.title, style: LsText.pageTitle),
              ),
              const SizedBox(height: LsSpace.xs),
              Text(v.body, style: LsText.subtitle),
              const SizedBox(height: 28),
              _Steps(steps: v.steps),
            ],
          ),
        ),
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (v.contactSupport && ApiConfig.supportEmail.isNotEmpty)
              LsButton(
                label: 'Copy research coordinator email',
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: ApiConfig.supportEmail),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Email address copied: ${ApiConfig.supportEmail}',
                        ),
                      ),
                    );
                  }
                },
              )
            else
              LsButton(
                label: 'Back to sign in',
                variant: restricted.status == AccountStatus.pendingApproval
                    ? LsButtonVariant.secondary
                    : LsButtonVariant.primary,
                onPressed: () {
                  close();
                  context.go(Routes.login);
                },
              ),
            const SizedBox(height: LsSpace.sm),
            Text(v.footnote, textAlign: TextAlign.center, style: LsText.helper),
          ],
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.steps});
  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(LsRadius.panel),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  _Dot(kind: steps[i].kind),
                  const SizedBox(width: LsSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].label,
                          style: LsText.bodySmall.copyWith(
                            height: 20 / 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(steps[i].status, style: LsText.helper),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.kind});
  final _StepKind kind;

  @override
  Widget build(BuildContext context) {
    final (
      Color bg,
      Border? border,
      IconData? icon,
      Color iconColor,
    ) = switch (kind) {
      _StepKind.done => (AppColors.primary, null, Icons.check, AppColors.text),
      _StepKind.failed => (
        AppColors.error,
        null,
        Icons.close,
        AppColors.surface,
      ),
      _StepKind.current => (
        LsTint.pendingDisc,
        Border.all(color: AppColors.warning, width: 2),
        null,
        AppColors.text,
      ),
      _StepKind.todo => (
        AppColors.surface,
        Border.all(color: AppColors.border, width: 1.5),
        null,
        AppColors.text,
      ),
    };
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        border: border,
        shape: BoxShape.circle,
      ),
      child: icon == null ? null : Icon(icon, size: 14, color: iconColor),
    );
  }
}
