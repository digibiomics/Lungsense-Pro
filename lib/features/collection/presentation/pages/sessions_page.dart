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
import '../../domain/entities/collection_session.dart';
import '../cubit/list_cubits.dart';
import '../widgets/collection_mode.dart';
import '../widgets/session_row.dart';

/// 14 Collection history (Sessions.dc.html) for doctors and 26 My
/// check-ins (PatientHistory.dc.html) for patients.
class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key, required this.mode, this.now});

  final CollectionMode mode;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionsCubit, SessionsState>(
      builder: (context, state) {
        final cubit = context.read<SessionsCubit>();
        return RolePage(
          title: mode.isPatient ? 'My check-ins' : 'Sessions',
          onRefresh: cubit.load,
          children: [
            _Filters(
              value: state.filter,
              patient: mode.isPatient,
              onChanged: cubit.setFilter,
            ),
            const SizedBox(height: LsSpace.md),
            ..._body(context, state, cubit),
          ],
        );
      },
    );
  }

  List<Widget> _body(
    BuildContext context,
    SessionsState state,
    SessionsCubit cubit,
  ) {
    if (state.loading && state.items.isEmpty) return const [SkeletonList()];
    if (state.failure != null) {
      return [
        LsBanner(
          tone: LsBannerTone.error,
          title: mode.isPatient
              ? 'Couldn\'t load your check-ins.'
              : 'Couldn\'t load sessions.',
          body: FailureMessages.generic(state.failure!).body,
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
      return [
        LsEmptyState(
          icon: mode.isPatient ? Icons.history : Icons.event_note_outlined,
          title: mode.isPatient ? 'No check-ins yet' : 'No sessions yet',
          body: mode.isPatient
              ? 'Each check-in you start appears here with its date and '
                    'status.'
              : 'Sessions you start appear here, with drafts you can resume.',
          action: mode.isPatient
              ? null
              : LsButton(
                  label: 'Start new collection',
                  onPressed: () => context.push(Routes.doctorStartCollection),
                ),
        ),
      ];
    }
    final t = now ?? DateTime.now();
    final groups = groupSessions(state.items, t, weekly: mode.isPatient);
    return [
      for (final g in groups) ...[
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(g.label, style: LsText.label),
        ),
        LsPanel(
          children: [
            for (final s in g.items)
              SessionRow(
                session: s,
                patient: mode.isPatient,
                now: t,
                title: mode.isPatient
                    ? (s.startedAt == null
                          ? 'Check-in'
                          : LsDates.weekdayDayMonth(s.startedAt!))
                    : s.studyId,
                onTap: () => context.push(mode.sessionPath(s.id)),
              ),
          ],
        ),
        const SizedBox(height: LsSpace.md),
      ],
      if (state.hasMore)
        LsButton(
          label: 'Show more',
          variant: LsButtonVariant.secondary,
          loading: state.loadingMore,
          onPressed: cubit.loadMore,
        ),
    ];
  }
}

/// Groups sessions newest first: by day ("Today", "Thursday, 22 October"),
/// or by week for patients ("This week", "Last week", "Earlier").
List<({String label, List<SessionSummary> items})> groupSessions(
  List<SessionSummary> sessions,
  DateTime now, {
  bool weekly = false,
}) {
  final sorted = [...sessions]
    ..sort(
      (a, b) =>
          (b.startedAt ?? DateTime(0)).compareTo(a.startedAt ?? DateTime(0)),
    );
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  String label(SessionSummary s) {
    final t = s.startedAt;
    if (t == null) return 'Date not recorded';
    if (!weekly) return LsDates.dayHeading(t, now);
    final l = t.toLocal();
    final day = DateTime(l.year, l.month, l.day);
    if (!day.isBefore(weekStart)) return 'This week';
    if (!day.isBefore(weekStart.subtract(const Duration(days: 7)))) {
      return 'Last week';
    }
    return 'Earlier';
  }

  final out = <({String label, List<SessionSummary> items})>[];
  for (final s in sorted) {
    final l = label(s);
    if (out.isEmpty || out.last.label != l) {
      out.add((label: l, items: [s]));
    } else {
      out.last.items.add(s);
    }
  }
  return out;
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.value,
    required this.patient,
    required this.onChanged,
  });

  final SessionFilter value;
  final bool patient;
  final ValueChanged<SessionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    String label(SessionFilter f) => switch (f) {
      SessionFilter.all => 'All',
      SessionFilter.drafts => patient ? 'Not finished' : 'Drafts',
      SessionFilter.completed => patient ? 'Submitted' : 'Completed',
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(LsRadius.control),
      ),
      child: Row(
        children: [
          for (final f in SessionFilter.values)
            Expanded(
              child: Semantics(
                selected: value == f,
                button: true,
                child: InkWell(
                  key: Key('filter_${f.name}'),
                  borderRadius: BorderRadius.circular(LsRadius.small),
                  onTap: () => onChanged(f),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == f ? LsTint.navActive : Colors.transparent,
                      borderRadius: BorderRadius.circular(LsRadius.small),
                    ),
                    child: Text(
                      label(f),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LsText.label.copyWith(
                        fontWeight: value == f
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
