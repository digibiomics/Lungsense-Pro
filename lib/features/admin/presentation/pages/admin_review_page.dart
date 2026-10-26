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
import '../../../authentication/domain/entities/app_user.dart';
import '../cubit/admin_cubits.dart';
import '../widgets/application_widgets.dart';

/// 28 Admin · review doctor (AdminReview.dc.html). Success is shown only
/// after the server confirms approve/reject.
class AdminReviewPage extends StatelessWidget {
  const AdminReviewPage({super.key});

  void _close(BuildContext context, AdminReviewState state) {
    if (context.canPop()) {
      context.pop(state.decided ? state.application : null);
    } else {
      context.go(Routes.adminHome);
    }
  }

  Future<void> _askReject(BuildContext context, String name) async {
    final cubit = context.read<AdminReviewCubit>();
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LsRadius.sheet),
        ),
      ),
      builder: (_) => RejectReasonSheet(name: name),
    );
    if (reason != null) await cubit.reject(reason);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminReviewCubit, AdminReviewState>(
      builder: (context, state) {
        final a = state.application;
        final cubit = context.read<AdminReviewCubit>();
        final p = a.doctorProfile;
        final fields = <(String, String?)>[
          ('Email', a.email),
          ('Licence no.', p?.licenseNumber),
          ('Specialty', p?.specialty),
          ('Institution', p?.institution),
          ('City', p?.city),
          ('Country', p?.country),
          ('Phone', p?.phone),
          ('Credential notes', p?.credentialNotes),
          if (a.submittedAt != null) ('Signed up', shortDate(a.submittedAt!)),
        ].where((f) => f.$2 != null && f.$2!.trim().isNotEmpty).toList();
        final pending =
            a.status == AccountStatus.pendingApproval ||
            a.status == AccountStatus.unknown;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close(context, state);
          },
          child: LsScreen(
            onBack: () => _close(context, state),
            backLabel: 'Approvals',
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    LsAvatar(name: a.displayName, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.displayName, style: LsText.screenTitle),
                          const SizedBox(height: 4),
                          statusPill(a.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LsSpace.lg),
                LsPanel(
                  children: [
                    for (final (k, v) in fields)
                      LsKeyValueRow(label: k, value: v!),
                  ],
                ),
                if (state.failure != null) ...[
                  const SizedBox(height: LsSpace.md),
                  Builder(
                    builder: (_) {
                      final copy = FailureMessages.generic(state.failure!);
                      return LsBanner(
                        tone: LsBannerTone.error,
                        title: 'Not saved. ${copy.title}',
                        body: copy.body,
                      );
                    },
                  ),
                ],
                if (state.decided && a.status == AccountStatus.active) ...[
                  const SizedBox(height: LsSpace.md),
                  LsBanner(
                    tone: LsBannerTone.success,
                    title: 'Approved.',
                    body: '${a.displayName} can now sign in and collect data.',
                  ),
                ],
                if (state.decided && a.status == AccountStatus.rejected) ...[
                  const SizedBox(height: LsSpace.md),
                  LsBanner(
                    tone: LsBannerTone.error,
                    title: 'Rejected.',
                    body:
                        'Reason sent: "${a.rejectionReason ?? ''}". Sign-in '
                        'is now refused for this account.',
                  ),
                ],
              ],
            ),
            bottomDivider: true,
            bottom: state.decided || !pending
                ? LsButton(
                    label: 'Back to approvals',
                    onPressed: () => _close(context, state),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: LsButton(
                          key: const Key('review_reject'),
                          label: 'Reject',
                          variant: LsButtonVariant.secondary,
                          loading: state.busy == ReviewAction.reject,
                          loadingLabel: 'Rejecting…',
                          onPressed: state.busy == null
                              ? () => _askReject(context, a.displayName)
                              : null,
                        ),
                      ),
                      const SizedBox(width: LsSpace.sm),
                      Expanded(
                        child: LsButton(
                          key: const Key('review_approve'),
                          label: 'Approve',
                          loading: state.busy == ReviewAction.approve,
                          loadingLabel: 'Approving…',
                          onPressed: state.busy == null ? cubit.approve : null,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet asking for the rejection reason (shown to the doctor).
class RejectReasonSheet extends StatefulWidget {
  const RejectReasonSheet({super.key, required this.name});
  final String name;

  @override
  State<RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<RejectReasonSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _reason.text.trim().isNotEmpty;
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
          Text('Reject ${widget.name}?', style: LsText.section),
          const SizedBox(height: LsSpace.md),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Reason '),
                TextSpan(text: '(shown to the doctor)', style: LsText.helper),
              ],
            ),
            style: LsText.label,
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('reject_reason'),
            controller: _reason,
            minLines: 3,
            maxLines: 5,
            autofocus: true,
            style: LsText.body,
            onChanged: (_) => setState(() {}),
          ),
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
                  key: const Key('reject_confirm'),
                  label: 'Reject',
                  variant: LsButtonVariant.destructive,
                  onPressed: ok
                      ? () => Navigator.of(context).pop(_reason.text.trim())
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

/// Shown when the review route is opened without an application (for
/// example a restored deep link): no single-doctor endpoint is documented.
class AdminReviewMissingPage extends StatelessWidget {
  const AdminReviewMissingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LsScreen(
      onBack: () => context.go(Routes.adminHome),
      backLabel: 'Approvals',
      body: const LsEmptyState(
        icon: Icons.search_off,
        title: 'Application not loaded',
        body: 'Open the doctor from the approvals list.',
      ),
      bottom: LsButton(
        label: 'Back to approvals',
        onPressed: () => context.go(Routes.adminHome),
      ),
    );
  }
}
