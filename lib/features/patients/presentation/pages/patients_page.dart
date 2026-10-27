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
import '../../../../core/widgets/ls_search_field.dart';
import '../../../admin/presentation/widgets/application_widgets.dart';
import '../../../authentication/presentation/widgets/role_page.dart';
import '../../domain/entities/patient.dart';
import '../cubit/patient_cubits.dart';

/// "54 y · Male · 1 session".
String patientMeta(PatientSummary p) => [
  if (p.ageYears != null) '${p.ageYears} y',
  if (p.sex != null && p.sex != PatientSex.unknown) p.sex!.label,
  '${p.sessionCount} session${p.sessionCount == 1 ? '' : 's'}',
].join(' · ');

/// 11 Patient list (Patients.dc.html).
class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key, this.now});
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientsCubit, PatientsState>(
      builder: (context, state) {
        final cubit = context.read<PatientsCubit>();
        return RolePage(
          title: 'Patients',
          onRefresh: cubit.load,
          trailing: TextButton.icon(
            key: const Key('patients_add'),
            onPressed: () => context.push(Routes.doctorAddPatient),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add patient'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.supportingGreen,
              minimumSize: const Size(LsSize.minTouch, LsSize.minTouch),
              textStyle: LsText.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          children: [
            LsSearchField(
              fieldKey: const Key('patients_search'),
              hint: 'Search patients',
              onChanged: cubit.search,
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
    PatientsState state,
    PatientsCubit cubit,
  ) {
    final q = state.query.trim();
    if (state.loading && state.items.isEmpty) return const [SkeletonList()];
    if (state.failure != null) {
      final copy = FailureMessages.generic(state.failure!);
      return [
        LsBanner(
          tone: LsBannerTone.error,
          title: 'Couldn\'t load patients.',
          body: copy.body,
        ),
        const SizedBox(height: LsSpace.md),
        LsButton(
          label: 'Try again',
          variant: LsButtonVariant.secondary,
          onPressed: cubit.load,
        ),
      ];
    }
    if (state.items.isEmpty && q.isNotEmpty) {
      return [
        LsEmptyState(
          icon: Icons.search_off,
          title: 'No patient matches "$q"',
          body: 'Check the ID, or add them as a new patient.',
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        LsEmptyState(
          icon: Icons.groups_outlined,
          title: 'No patients yet',
          body:
              'Patients you register appear here. Each one gets an ID to use '
              'during collection.',
          action: LsButton(
            label: 'Add your first patient',
            onPressed: () => context.push(Routes.doctorAddPatient),
          ),
        ),
      ];
    }
    final t = now ?? DateTime.now();
    return [
      Text(
        q.isEmpty
            ? '${state.total} patient${state.total == 1 ? '' : 's'} · most recent first'
            : '${state.items.length} of ${state.total} patients',
        style: LsText.helper,
      ),
      const SizedBox(height: LsSpace.xs),
      LsPanel(
        children: [
          for (final p in state.items)
            PatientRow(
              patient: p,
              trailing: p.lastSessionAt == null
                  ? null
                  : LsDates.shortDay(p.lastSessionAt!, t),
              onTap: () => context.push(Routes.doctorPatientFor(p.id)),
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

/// List row: study ID, meta line, optional trailing text and chevron.
class PatientRow extends StatelessWidget {
  const PatientRow({
    super.key,
    required this.patient,
    required this.onTap,
    this.trailing,
    this.selected,
  });

  final PatientSummary patient;
  final VoidCallback onTap;
  final String? trailing;

  /// Non-null shows a radio (Start collection).
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final p = patient;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: selected != null,
      button: true,
      child: InkWell(
        key: Key('patient_${p.id}'),
        onTap: onTap,
        child: Container(
          color: selected == true ? LsTint.selectedCard : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (selected != null) ...[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected!
                          ? AppColors.supportingGreen
                          : AppColors.textSecondary,
                      width: selected! ? 2 : 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: selected!
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.supportingGreen,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: LsSpace.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p.studyId, style: LsText.listTitle),
                        if (p.isArchived) ...[
                          const SizedBox(width: 8),
                          const LsStatusPill(
                            label: 'Archived',
                            tone: LsPillTone.neutral,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(patientMeta(p), style: LsText.helper),
                  ],
                ),
              ),
              if (trailing != null) Text(trailing!, style: LsText.helper),
              if (selected == null)
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
