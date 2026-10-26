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
import '../../../authentication/presentation/widgets/role_page.dart';
import '../../domain/entities/doctor_application.dart';
import '../cubit/admin_cubits.dart';
import '../widgets/application_widgets.dart';

/// 27 Admin · doctor approvals (AdminDoctors.dc.html).
class AdminDoctorsPage extends StatelessWidget {
  const AdminDoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDoctorsCubit, AdminDoctorsState>(
      builder: (context, state) {
        final cubit = context.read<AdminDoctorsCubit>();
        return RolePage(
          eyebrow: 'Admin',
          title: 'Doctor approvals',
          onRefresh: cubit.load,
          children: [
            _Tabs(state: state, onSelect: cubit.selectTab),
            const SizedBox(height: LsSpace.md),
            ..._body(context, state, cubit),
          ],
        );
      },
    );
  }

  List<Widget> _body(
    BuildContext context,
    AdminDoctorsState state,
    AdminDoctorsCubit cubit,
  ) {
    if (state.loading && state.items.isEmpty) return const [SkeletonList()];
    if (state.failure != null && state.items.isEmpty) {
      final copy = FailureMessages.generic(state.failure!);
      return [
        LsBanner(
          tone: LsBannerTone.error,
          title: 'Couldn\'t load applications.',
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
    final rows = state.visible;
    if (rows.isEmpty) {
      return [
        LsEmptyState(
          icon: Icons.verified_user_outlined,
          title: switch (state.tab) {
            ApplicationTab.pending => 'No applications waiting',
            ApplicationTab.approved => 'No approved doctors',
            ApplicationTab.rejected => 'No rejected applications',
          },
          body: 'Pull down to check again.',
        ),
      ];
    }
    return [
      LsPanel(
        children: [
          for (final a in rows)
            _Row(
              application: a,
              onTap: () async {
                final updated = await context.push<DoctorApplication>(
                  Routes.adminReviewFor(a.userId),
                  extra: a,
                );
                if (updated != null) await cubit.applyDecision(updated);
              },
            ),
        ],
      ),
    ];
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.state, required this.onSelect});
  final AdminDoctorsState state;
  final ValueChanged<ApplicationTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(LsRadius.control),
      ),
      child: Row(
        children: [
          for (final t in ApplicationTab.values)
            Expanded(
              child: Semantics(
                selected: state.tab == t,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(LsRadius.small),
                  onTap: () => onSelect(t),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: state.tab == t
                          ? LsTint.navActive
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(LsRadius.small),
                    ),
                    child: Text(
                      state.loading && state.items.isEmpty
                          ? t.label
                          : '${t.label} (${state.count(t)})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LsText.label.copyWith(
                        fontWeight: state.tab == t
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.application, required this.onTap});
  final DoctorApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = application;
    final meta = applicationMeta(a);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LsAvatar(name: a.displayName),
            const SizedBox(width: LsSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.displayName, style: LsText.listTitle),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(meta, style: LsText.helper),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    a.submittedAt == null
                        ? a.email
                        : 'Signed up ${shortDate(a.submittedAt!)}',
                    style: LsText.helper,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
