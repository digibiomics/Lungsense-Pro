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
import '../../../authentication/presentation/widgets/role_page.dart';
import '../../../collection/domain/entities/recording.dart';
import '../../../collection/presentation/cubit/list_cubits.dart';
import '../../../collection/presentation/widgets/session_row.dart';
import '../../../patients/domain/entities/patient.dart';
import '../../../patients/presentation/cubit/patient_cubits.dart';

/// 25 Patient home (PatientHome.dc.html): today's check-in and recent
/// check-ins. Starting a check-in creates a session on the server first.
class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key, this.now});

  /// Injectable clock for tests.
  final DateTime? now;

  Future<void> _start(BuildContext context) async {
    final s = await context.read<StartSessionCubit>().start();
    if (!context.mounted) return;
    if (s != null) {
      context.push(Routes.patientCheckInFor(s.id));
    } else {
      // A refusal may be the consent rule; re-read it so the consent step
      // shows when that is the reason.
      context.read<MyConsentCubit>().load();
    }
  }

  Future<void> _giveConsent(BuildContext context) async {
    final ok = await context.read<MyConsentCubit>().give();
    if (ok && context.mounted) context.read<StartSessionCubit>().reset();
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser(context);
    final today = now ?? DateTime.now();
    final name = user == null ? '' : firstName(user);
    final starting = context.watch<StartSessionCubit>().state;
    final consent = context.watch<MyConsentCubit>().state;
    return BlocBuilder<PatientHomeCubit, PatientHomeState>(
      builder: (context, state) {
        final cubit = context.read<PatientHomeCubit>();
        final draft = state.todaysDraft(today);
        final done = state.todaysCompleted(today);
        final (String pill, LsPillTone tone) = done != null
            ? ('Done today', LsPillTone.success)
            : draft != null
            ? ('In progress', LsPillTone.pending)
            : ('Not done yet', LsPillTone.neutral);
        return RolePage(
          eyebrow: formatLongDate(today),
          title: name.isEmpty ? 'Hello' : 'Hello, $name',
          onRefresh: cubit.load,
          trailing: user == null
              ? null
              : Semantics(
                  button: true,
                  label: 'Profile',
                  child: GestureDetector(
                    onTap: () => context.go(Routes.patientProfile),
                    child: LsAvatar(name: user.displayName),
                  ),
                ),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(LsRadius.hero),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Today\'s check-in', style: LsText.section),
                      ),
                      if (!state.loading || state.recent.isNotEmpty)
                        LsStatusPill(label: pill, tone: tone),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final (icon, label) in [
                    (
                      Icons.mic_none_outlined,
                      'Cough · ${RecordingType.cough.max} s',
                    ),
                    (Icons.air, 'Breathing · ${RecordingType.breathing.max} s'),
                    (Icons.checklist, 'Symptoms'),
                    (Icons.notes_outlined, 'Context · optional'),
                  ]) ...[
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: LsTint.iconDisc,
                            borderRadius: BorderRadius.circular(LsRadius.small),
                          ),
                          child: Icon(icon, size: 18, color: AppColors.text),
                        ),
                        const SizedBox(width: LsSpace.sm),
                        Expanded(child: Text(label, style: LsText.bodySmall)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 4),
                  if (done != null)
                    LsButton(
                      label: 'View today\'s check-in',
                      variant: LsButtonVariant.secondary,
                      onPressed: () =>
                          context.push(Routes.patientCheckInFor(done.id)),
                    )
                  else if (consent.needed)
                    _ConsentStep(
                      state: consent,
                      onGive: () => _giveConsent(context),
                    )
                  else if (draft != null)
                    LsButton(
                      key: const Key('checkin_continue'),
                      label: 'Continue check-in',
                      onPressed: () =>
                          context.push(Routes.patientCheckInFor(draft.id)),
                    )
                  else
                    LsButton(
                      key: const Key('checkin_start'),
                      label: 'Start check-in · about 3 min',
                      loading: starting.starting,
                      loadingLabel: 'Starting…',
                      onPressed: state.loading && state.recent.isEmpty
                          ? null
                          : () => _start(context),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Find a quiet room before you start.',
                    textAlign: TextAlign.center,
                    style: LsText.helper,
                  ),
                  if (starting.failure != null && !consent.needed) ...[
                    const SizedBox(height: LsSpace.sm),
                    LsBanner(
                      tone: LsBannerTone.error,
                      title: 'Check-in not started.',
                      body:
                          starting.failure!.message ??
                          FailureMessages.generic(starting.failure!).body,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: LsSpace.lg),
            Row(
              children: [
                Expanded(
                  child: Text('Recent check-ins', style: LsText.section),
                ),
                if (state.recent.isNotEmpty)
                  LsLinkButton(
                    label: 'See all',
                    onPressed: () => context.go(Routes.patientCheckIns),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (state.failure != null && state.recent.isEmpty)
              LsBanner(
                tone: LsBannerTone.error,
                title: 'Couldn\'t load your check-ins.',
                body: FailureMessages.generic(state.failure!).body,
                actionLabel: 'Try again',
                onAction: cubit.load,
              )
            else if (state.recent.isEmpty && !state.loading)
              const LsEmptyState(
                icon: Icons.history,
                title: 'No check-ins yet',
                body: 'Your check-ins will be listed here.',
              )
            else if (state.recent.isNotEmpty)
              LsPanel(
                children: [
                  for (final s in state.recent)
                    SessionRow(
                      session: s,
                      patient: true,
                      now: today,
                      title: s.startedAt == null
                          ? 'Check-in'
                          : LsDates.weekdayDayMonth(s.startedAt!),
                      onTap: () => context.push(Routes.patientCheckInFor(s.id)),
                    ),
                ],
              ),
            const SizedBox(height: LsSpace.lg),
            Text(
              'Your recordings are used for research only. This app does not '
              'diagnose or give medical advice.',
              textAlign: TextAlign.center,
              style: LsText.footnote,
            ),
          ],
        );
      },
    );
  }
}

/// Shown instead of "Start check-in" while the patient's record has no
/// research consent: the server refuses new check-ins until it is given.
class _ConsentStep extends StatefulWidget {
  const _ConsentStep({required this.state, required this.onGive});

  final MyConsentState state;
  final VoidCallback onGive;

  @override
  State<_ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends State<_ConsentStep> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LsBanner(
          tone: LsBannerTone.info,
          title: s.consent == ConsentStatus.withdrawn
              ? 'You withdrew your research consent.'
              : 'Your research consent is needed first.',
          body:
              'Check-ins are collected for a research study, so your '
              'consent is recorded before your first check-in.',
        ),
        const SizedBox(height: LsSpace.sm),
        LsCheckboxTile(
          key: const Key('checkin_consent'),
          value: _agreed,
          onChanged: (v) {
            if (!s.saving) setState(() => _agreed = v);
          },
          child: const Text(
            'I agree to take part in the research study and for my '
            'recordings and answers to be used for research.',
          ),
        ),
        const SizedBox(height: LsSpace.sm),
        LsButton(
          key: const Key('checkin_consent_give'),
          label: 'Give consent',
          loading: s.saving,
          loadingLabel: 'Saving…',
          onPressed: _agreed ? widget.onGive : null,
        ),
        if (s.failure != null) ...[
          const SizedBox(height: LsSpace.sm),
          LsBanner(
            tone: LsBannerTone.error,
            title: 'Consent not saved.',
            body: FailureMessages.generic(s.failure!).body,
          ),
        ],
      ],
    );
  }
}
