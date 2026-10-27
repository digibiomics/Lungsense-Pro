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
import '../../../collection/presentation/widgets/session_row.dart';
import '../../domain/entities/patient.dart';
import '../cubit/patient_cubits.dart';

/// 13 Patient detail (PatientDetail.dc.html).
class PatientDetailPage extends StatelessWidget {
  const PatientDetailPage({super.key, this.now});
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientDetailCubit, PatientDetailState>(
      builder: (context, state) {
        final cubit = context.read<PatientDetailCubit>();
        final p = state.patient;
        return Scaffold(
          appBar: AppBar(
            title: Text(p == null ? 'Patient' : 'Patient ${p.studyId}'),
            actions: [
              if (p != null)
                TextButton(
                  key: const Key('patient_edit'),
                  onPressed: () async {
                    final updated = await context.push<Patient>(
                      Routes.doctorEditPatientFor(p.id),
                    );
                    if (updated != null) cubit.applyUpdate(updated);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.supportingGreen,
                  ),
                  child: const Text('Edit'),
                ),
            ],
          ),
          body: p == null
              ? (state.failure == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.supportingGreen,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(LsSpace.gutter),
                        child: LsBanner(
                          tone: LsBannerTone.error,
                          title: 'Couldn\'t load this patient.',
                          body: FailureMessages.generic(state.failure!).body,
                          actionLabel: 'Try again',
                          onAction: cubit.load,
                        ),
                      ))
              : RefreshIndicator(
                  color: AppColors.supportingGreen,
                  onRefresh: cubit.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      LsSpace.gutter,
                      LsSpace.xs,
                      LsSpace.gutter,
                      LsSpace.xl,
                    ),
                    children: _content(context, state, p),
                  ),
                ),
        );
      },
    );
  }

  List<Widget> _content(
    BuildContext context,
    PatientDetailState state,
    Patient p,
  ) {
    final t = now ?? DateTime.now();
    final fields = <(String, String?)>[
      ('Hospital ref.', p.externalId),
      if (p.createdAt != null)
        ('Registered', LsDates.dayMonthYear(p.createdAt!)),
      if (p.ageYears != null) ('Age', '${p.ageYears} years'),
      if (p.sex != null) ('Sex', p.sex!.label),
      ('Research consent', p.consent.label),
      if (p.relevantHistory != null && p.relevantHistory!.trim().isNotEmpty)
        ('Notes', p.relevantHistory),
    ].where((f) => f.$2 != null && f.$2!.isNotEmpty).toList();

    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(LsRadius.hero),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient',
              style: LsText.helper.copyWith(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Expanded(child: Text(p.studyId, style: LsText.authTitle)),
                if (p.isArchived)
                  const LsStatusPill(
                    label: 'Archived',
                    tone: LsPillTone.neutral,
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: LsSpace.sm),
      LsPanel(
        children: [
          for (final f in fields) LsKeyValueRow(label: f.$1, value: f.$2!),
        ],
      ),
      if (p.consent != ConsentStatus.given) ...[
        const SizedBox(height: LsSpace.sm),
        LsBanner(
          tone: LsBannerTone.warning,
          title: p.consent == ConsentStatus.withdrawn
              ? 'Consent withdrawn.'
              : 'Consent not recorded.',
          body: 'Record consent with Edit before collecting data.',
        ),
      ],
      const SizedBox(height: LsSpace.lg),
      LsButton(
        key: const Key('patient_start'),
        label: 'Start new collection',
        icon: const Icon(Icons.add, size: 20),
        onPressed: p.isArchived
            ? null
            : () => context.push(
                Routes.startCollectionFor(patientId: p.id, studyId: p.studyId),
              ),
      ),
      const SizedBox(height: LsSpace.lg),
      Text('Collection sessions', style: LsText.section),
      const SizedBox(height: 10),
      if (state.sessionsFailure != null)
        LsBanner(
          tone: LsBannerTone.error,
          title: 'Couldn\'t load sessions.',
          body: FailureMessages.generic(state.sessionsFailure!).body,
        )
      else if (state.sessions.isEmpty)
        Text('No sessions yet.', style: LsText.helper)
      else
        LsPanel(
          children: [
            for (final s in state.sessions)
              SessionRow(
                session: s,
                title: s.startedAt == null
                    ? 'Session'
                    : LsDates.shortDay(s.startedAt!, t),
                now: t,
                onTap: () => context.push(Routes.doctorSessionFor(s.id)),
              ),
          ],
        ),
    ];
  }
}
