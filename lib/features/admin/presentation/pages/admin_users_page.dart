import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_search_field.dart';
import '../../../../core/widgets/ls_sheet.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/widgets/role_page.dart';
import '../../domain/entities/admin_user.dart';
import '../cubit/admin_users_cubit.dart';
import '../widgets/application_widgets.dart';

/// 29 Admin · users (AdminUsers.dc.html): search, suspend, reactivate.
class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  Future<void> _suspend(BuildContext context, AdminUser u) async {
    final cubit = context.read<AdminUsersCubit>();
    final r = await showLsSheet<LsConfirmResult>(
      context,
      LsConfirmSheet(
        title: 'Suspend ${u.displayName}?',
        body:
            'They won\'t be able to sign in from their next request. Their '
            'submitted data stays in the study.',
        confirmLabel: 'Suspend',
        variant: LsButtonVariant.destructive,
        reasonLabel: 'Reason (optional)',
        reasonMaxLength: 1000,
        confirmKey: const Key('suspend_confirm'),
      ),
    );
    if (r != null) {
      await cubit.changeStatus(u, UserStatusChange.suspended, reason: r.reason);
    }
  }

  Future<void> _reactivate(BuildContext context, AdminUser u) async {
    final cubit = context.read<AdminUsersCubit>();
    final r = await showLsSheet<LsConfirmResult>(
      context,
      LsConfirmSheet(
        title: 'Reactivate ${u.displayName}?',
        body: 'They can sign in again straight away.',
        confirmLabel: 'Reactivate',
        confirmKey: const Key('reactivate_confirm'),
      ),
    );
    if (r != null) await cubit.changeStatus(u, UserStatusChange.active);
  }

  @override
  Widget build(BuildContext context) {
    final me = currentUser(context);
    return BlocConsumer<AdminUsersCubit, AdminUsersState>(
      listenWhen: (a, b) =>
          b.lastChanged != null && a.lastChanged != b.lastChanged,
      listener: (context, state) {
        final u = state.lastChanged!;
        showLsToast(
          context,
          u.status == AccountStatus.suspended
              ? '${u.displayName} is suspended.'
              : '${u.displayName} is active again.',
        );
      },
      builder: (context, state) {
        final cubit = context.read<AdminUsersCubit>();
        return RolePage(
          eyebrow: 'Admin',
          title: 'Users',
          onRefresh: cubit.load,
          children: [
            LsSearchField(
              fieldKey: const Key('users_search'),
              hint: 'Search users',
              onChanged: cubit.search,
            ),
            const SizedBox(height: LsSpace.md),
            if (state.actionFailure != null) ...[
              LsBanner(
                tone: LsBannerTone.error,
                title: 'Status not changed.',
                body: FailureMessages.generic(state.actionFailure!).body,
              ),
              const SizedBox(height: LsSpace.md),
            ],
            ..._body(context, state, cubit, me),
            const SizedBox(height: LsSpace.md),
            Text(
              'Suspended users can\'t sign in. Their submitted data stays in '
              'the study.',
              textAlign: TextAlign.center,
              style: LsText.helper,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _body(
    BuildContext context,
    AdminUsersState state,
    AdminUsersCubit cubit,
    AppUser? me,
  ) {
    if (state.loading && state.items.isEmpty) return const [SkeletonList()];
    if (state.failure != null) {
      final copy = FailureMessages.generic(state.failure!);
      return [
        LsBanner(
          tone: LsBannerTone.error,
          title: 'Couldn\'t load users.',
          body: '${copy.title} ${copy.body}',
        ),
        const SizedBox(height: LsSpace.md),
        LsButton(
          label: 'Try again',
          variant: LsButtonVariant.secondary,
          onPressed: cubit.load,
        ),
      ];
    }
    if (state.items.isEmpty) {
      final q = state.query.trim();
      return [
        LsEmptyState(
          icon: Icons.manage_accounts_outlined,
          title: q.isEmpty ? 'No users yet' : 'No user matches "$q"',
          body: q.isEmpty
              ? 'Accounts appear here once people sign up.'
              : 'Check the spelling, or search by email.',
        ),
      ];
    }
    return [
      LsPanel(
        children: [
          for (final u in state.items)
            _UserRow(
              user: u,
              busy: state.busyUserId == u.id,
              // Admins can't suspend themselves from here.
              actionsEnabled: state.busyUserId == null && u.id != me?.id,
              onSuspend: () => _suspend(context, u),
              onReactivate: () => _reactivate(context, u),
            ),
        ],
      ),
      if (state.hasMore) ...[
        const SizedBox(height: LsSpace.sm),
        LsButton(
          label: 'Show more',
          variant: LsButtonVariant.secondary,
          loading: state.loadingMore,
          onPressed: cubit.loadMore,
        ),
      ],
    ];
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.busy,
    required this.actionsEnabled,
    required this.onSuspend,
    required this.onReactivate,
  });

  final AdminUser user;
  final bool busy;
  final bool actionsEnabled;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final u = user;
    final role = switch (u.role) {
      UserRole.doctor => 'Doctor',
      UserRole.patient => 'Patient',
      UserRole.admin => 'Admin',
      UserRole.newUser => 'No account type yet',
      UserRole.unknown => 'Unknown role',
    };
    final String? action = u.canSuspend
        ? 'Suspend'
        : u.canReactivate
        ? 'Reactivate'
        : null;
    return Padding(
      key: Key('user_${u.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          LsAvatar(name: u.displayName, size: 40),
          const SizedBox(width: LsSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.displayName, style: LsText.listTitle),
                const SizedBox(height: 2),
                Text(
                  u.email,
                  style: LsText.helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(role, style: LsText.helper),
                    statusPill(u.status),
                  ],
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: LsSpace.xs),
            SizedBox(
              height: LsSize.minTouch,
              child: OutlinedButton(
                key: Key('user_action_${u.id}'),
                onPressed: actionsEnabled
                    ? (u.canSuspend ? onSuspend : onReactivate)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: BorderSide(
                    color: u.canReactivate
                        ? AppColors.supportingGreen
                        : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LsRadius.small),
                  ),
                  textStyle: LsText.label.copyWith(fontWeight: FontWeight.w600),
                ),
                child: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(action),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
