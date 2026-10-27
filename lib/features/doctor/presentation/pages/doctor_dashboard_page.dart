import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../admin/presentation/widgets/application_widgets.dart';
import '../../../authentication/presentation/widgets/role_page.dart';
import '../../../collection/domain/entities/collection_session.dart';
import '../../../collection/presentation/cubit/list_cubits.dart';

/// 10 Doctor dashboard (Dashboard.dc.html): counts, drafts to finish and
/// recent activity, all from the server.
class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final user = currentUser(context);
    final t = now ?? DateTime.now();
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final cubit = context.read<DashboardCubit>();
        return RolePage(
          eyebrow: formatLongDate(t),
          title: user == null
              ? greetingFor(t)
              : '${greetingFor(t)}, ${user.displayName}',
          onRefresh: cubit.load,
          trailing: user == null
              ? null
              : Semantics(
                  button: true,
                  label: 'Profile',
                  child: GestureDetector(
                    onTap: () => context.go(Routes.doctorProfile),
                    child: LsAvatar(name: user.displayName),
                  ),
                ),
          children: [
            LsButton(
              key: const Key('dashboard_start'),
              label: 'Start new collection',
              icon: const Icon(Icons.add, size: 20),
              height: 56,
              onPressed: () => context.push(Routes.doctorStartCollection),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a patient, then record cough and breathing.',
              textAlign: TextAlign.center,
              style: LsText.helper,
            ),
            const SizedBox(height: LsSpace.lg),
            ..._body(context, state, cubit, t),
          ],
        );
      },
    );
  }

  List<Widget> _body(
    BuildContext context,
    DashboardState state,
    DashboardCubit cubit,
    DateTime t,
  ) {
    final stats = state.stats;
    if (stats == null && state.failure == null) {
      return const [SkeletonList(rows: 2)];
    }
    if (stats == null) {
      return [
        LsBanner(
          tone: LsBannerTone.error,
          title: 'Couldn\'t load your dashboard.',
          body: FailureMessages.generic(state.failure!).body,
          actionLabel: 'Try again',
          onAction: cubit.load,
        ),
      ];
    }
    if (stats.isEmpty) {
      return [
        LsEmptyState(
          icon: Icons.folder_open_outlined,
          title: 'No collections yet',
          body:
              'Register your first patient to begin. Their sessions will '
              'appear here.',
          action: LsButton(
            label: 'Add a patient',
            variant: LsButtonVariant.secondary,
            onPressed: () => context.push(Routes.doctorAddPatient),
          ),
        ),
      ];
    }
    return [
      Row(
        children: [
          _Stat(value: stats.patientsRegistered, label: 'Patients'),
          const SizedBox(width: LsSpace.xs),
          _Stat(value: stats.sessionsTotal, label: 'Sessions'),
          const SizedBox(width: LsSpace.xs),
          _Stat(value: stats.sessionsDraft, label: 'Drafts'),
        ],
      ),
      if (stats.recordingsFailedQc > 0 || stats.incompleteUploads > 0) ...[
        const SizedBox(height: LsSpace.sm),
        LsBanner(
          tone: LsBannerTone.warning,
          title: 'Needs attention.',
          body: [
            if (stats.recordingsFailedQc > 0)
              '${stats.recordingsFailedQc} recording'
                  '${stats.recordingsFailedQc == 1 ? '' : 's'} failed the '
                  'quality check.',
            if (stats.incompleteUploads > 0)
              '${stats.incompleteUploads} upload'
                  '${stats.incompleteUploads == 1 ? '' : 's'} didn\'t finish.',
          ].join(' '),
        ),
      ],
      if (state.failure != null) ...[
        const SizedBox(height: LsSpace.sm),
        LsBanner(
          tone: LsBannerTone.error,
          title: 'Couldn\'t refresh.',
          body: FailureMessages.generic(state.failure!).body,
        ),
      ],
      if (state.drafts.isNotEmpty) ...[
        const SizedBox(height: LsSpace.lg),
        Text('Drafts to finish', style: LsText.section),
        const SizedBox(height: 10),
        LsPanel(
          children: [
            for (final d in state.drafts) _DraftRow(session: d, now: t),
          ],
        ),
      ],
      if (stats.recent.isNotEmpty) ...[
        const SizedBox(height: LsSpace.lg),
        Row(
          children: [
            Expanded(child: Text('Recent activity', style: LsText.section)),
            LsLinkButton(
              label: 'View all',
              onPressed: () => context.go(Routes.doctorSessions),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LsPanel(
          children: [
            for (final r in stats.recent)
              InkWell(
                onTap: () => context.push(Routes.doctorSessionFor(r.sessionId)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: r.studyId,
                                style: LsText.listTitle,
                              ),
                              TextSpan(
                                text: r.status == SessionStatus.completed
                                    ? ' · session submitted'
                                    : ' · session started',
                              ),
                            ],
                          ),
                          style: LsText.bannerBody,
                        ),
                      ),
                      if ((r.completedAt ?? r.startedAt) != null)
                        Text(
                          LsDates.dayAndTime(r.completedAt ?? r.startedAt!, t),
                          style: LsText.helper,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ];
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(LsRadius.panel),
        ),
        child: Semantics(
          label: '$value $label',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: LsText.screenTitle),
              Text(label, style: LsText.helper),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({required this.session, required this.now});
  final SessionSummary session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final saved = s.updatedAt ?? s.startedAt;
    return InkWell(
      onTap: () => context.push(Routes.doctorSessionFor(s.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.studyId, style: LsText.listTitle),
                  const SizedBox(height: 2),
                  Text(
                    [
                      '${s.counts.requiredDone} of 3 required steps',
                      if (saved != null)
                        'saved ${LsDates.dayAndTime(saved, now).toLowerCase()}',
                    ].join(' · '),
                    style: LsText.helper,
                  ),
                ],
              ),
            ),
            Text(
              'Resume',
              style: LsText.label.copyWith(
                color: AppColors.supportingGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
