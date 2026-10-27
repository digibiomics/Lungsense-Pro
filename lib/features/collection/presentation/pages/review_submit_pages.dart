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
import '../../../../core/widgets/ls_sheet.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/symptoms.dart';
import '../cubit/collection_session_cubit.dart';
import '../cubit/step_cubits.dart';
import '../widgets/collection_mode.dart';
import '../widgets/collection_widgets.dart';
import 'session_overview_page.dart';

CollectionRoute _routeFor(CollectionStep s) => switch (s) {
  CollectionStep.cough => CollectionRoute.cough,
  CollectionStep.breathing => CollectionRoute.breathing,
  CollectionStep.symptoms => CollectionRoute.symptoms,
};

/// 22 Review (Review.dc.html): summary, missing items from the server,
/// confirm sheet, dark Submit button.
class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key, required this.mode, this.now});
  final CollectionMode mode;
  final DateTime? now;

  Future<void> _confirm(BuildContext context, CollectionSession s) async {
    final who = mode.isPatient ? 'your check-in' : s.studyId;
    final r = await showLsSheet<LsConfirmResult>(
      context,
      LsConfirmSheet(
        title: mode.isPatient
            ? 'Submit this check-in?'
            : 'Submit this session?',
        body:
            'Cough, breathing, symptoms and clinical context for $who will be '
            'sent to the research team. You won\'t be able to edit '
            '${mode.isPatient ? 'it' : 'the session'} afterwards.',
        confirmLabel: 'Submit',
        variant: LsButtonVariant.submitDark,
        confirmKey: const Key('review_confirm'),
      ),
    );
    if (r != null && context.mounted) {
      context.pushReplacement(mode.stepPath(s.id, CollectionRoute.submit));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionSessionCubit, CollectionSessionState>(
      builder: (context, state) {
        final cubit = context.read<CollectionSessionCubit>();
        final s = state.session;
        if (s == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Review session')),
            body: SessionLoadState(failure: state.failure, onRetry: cubit.load),
          );
        }
        if (!s.isDraft) return SessionDetailView(session: s, mode: mode);
        final t = now ?? DateTime.now();
        void open(CollectionRoute r) =>
            context.pushReplacement(mode.stepPath(s.id, r));

        LsStepState stateFor(CollectionStep step) =>
            s.isDone(step) ? LsStepState.done : LsStepState.missing;
        final symptoms = s.symptoms;
        final missingCount = s.missing.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(mode.isPatient ? 'Review check-in' : 'Review session'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              LsSpace.gutter,
              LsSpace.xs,
              LsSpace.gutter,
              LsSpace.lg,
            ),
            children: [
              PatientIdCard(
                label: mode.isPatient ? 'Your check-in' : 'Patient',
                id: mode.isPatient
                    ? LsDates.dayHeading(s.summary.startedAt ?? t, t)
                    : s.studyId,
                meta: startedLabel(s.summary, t),
              ),
              const SizedBox(height: LsSpace.md),
              if (missingCount > 0) ...[
                LsBanner(
                  tone: LsBannerTone.error,
                  title:
                      '$missingCount required item${missingCount == 1 ? '' : 's'} missing.',
                  body:
                      'Complete ${s.missing.map((m) => m.label.toLowerCase()).join(', ')} before submitting.',
                ),
                const SizedBox(height: LsSpace.md),
              ],
              LsPanel(
                children: [
                  LsStepRow(
                    state: stateFor(CollectionStep.cough),
                    number: 1,
                    title: 'Cough recording',
                    note: _rec(s.latest(RecordingType.cough)),
                    action: s.isDone(CollectionStep.cough)
                        ? 'Change'
                        : 'Complete',
                    onAction: () => open(CollectionRoute.cough),
                  ),
                  LsStepRow(
                    state: stateFor(CollectionStep.breathing),
                    number: 2,
                    title: 'Breathing recording',
                    note: _rec(s.latest(RecordingType.breathing)),
                    action: s.isDone(CollectionStep.breathing)
                        ? 'Change'
                        : 'Complete',
                    onAction: () => open(CollectionRoute.breathing),
                  ),
                  LsStepRow(
                    state: stateFor(CollectionStep.symptoms),
                    number: 3,
                    title: 'Symptoms',
                    note: symptoms == null
                        ? 'Required · not rated'
                        : symptomsNote(symptoms),
                    action: s.isDone(CollectionStep.symptoms)
                        ? 'Change'
                        : 'Complete',
                    onAction: () => open(CollectionRoute.symptoms),
                  ),
                  LsStepRow(
                    state: LsStepState.done,
                    number: 4,
                    title: 'Clinical context',
                    note: contextNote(s),
                    action: 'Change',
                    onAction: () => open(CollectionRoute.context),
                  ),
                ],
              ),
              const SizedBox(height: LsSpace.md),
              LsNote(
                bordered: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After you submit, the ${mode.isPatient ? 'check-in' : 'session'} '
                        'is locked and sent to the research team. It can\'t '
                        'be edited.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(
                LsSpace.gutter,
                LsSpace.sm,
                LsSpace.gutter,
                LsSpace.md,
              ),
              child: LsButton(
                key: const Key('review_submit'),
                label: mode.isPatient ? 'Submit check-in' : 'Submit session',
                variant: LsButtonVariant.submitDark,
                onPressed: missingCount == 0
                    ? () => _confirm(context, s)
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  static String _rec(AudioRecording? r) =>
      r == null ? 'Required · not recorded' : recordingNote(r);
}

/// 23 Submit result (SubmitResult.dc.html): submitting, success,
/// missingItems, failed.
class SubmitResultPage extends StatelessWidget {
  const SubmitResultPage({super.key, required this.mode});
  final CollectionMode mode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubmitCubit, SubmitState>(
      builder: (context, state) {
        final cubit = context.read<SubmitCubit>();
        final id = cubit.sessionId;
        return PopScope(
          canPop: state.phase != SubmitPhase.submitting,
          child: Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(LsSpace.authGutter),
                children: switch (state.phase) {
                  SubmitPhase.submitting => [
                    const SizedBox(height: 120),
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.supportingGreen,
                      ),
                    ),
                    const SizedBox(height: LsSpace.lg),
                    Text(
                      mode.isPatient
                          ? 'Submitting check-in…'
                          : 'Submitting session…',
                      textAlign: TextAlign.center,
                      style: LsText.screenTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep the app open until the server confirms.',
                      textAlign: TextAlign.center,
                      style: LsText.subtitle,
                    ),
                  ],
                  SubmitPhase.success => _success(context, state),
                  SubmitPhase.missing => [
                    const SizedBox(height: LsSpace.xl),
                    _Disc(icon: Icons.error_outline, color: LsTint.cautionBg),
                    const SizedBox(height: LsSpace.md),
                    Text(
                      'Not submitted yet',
                      textAlign: TextAlign.center,
                      style: LsText.authTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The server needs these items before it can complete '
                      'the ${mode.isPatient ? 'check-in' : 'session'}. Your '
                      'draft is saved.',
                      textAlign: TextAlign.center,
                      style: LsText.subtitle,
                    ),
                    const SizedBox(height: LsSpace.lg),
                    LsPanel(
                      children: [
                        for (final m in state.missing)
                          LsStepRow(
                            state: LsStepState.missing,
                            number: 0,
                            title: m.label,
                            note: 'Required',
                            action: 'Fix',
                            onAction: () => context.pushReplacement(
                              mode.stepPath(id, _routeFor(m)),
                            ),
                          ),
                        if (state.missing.isEmpty)
                          const LsKeyValueRow(
                            label: 'Missing',
                            value: 'The server did not say which items.',
                          ),
                      ],
                    ),
                    const SizedBox(height: LsSpace.lg),
                    LsButton(
                      label: 'Back to review',
                      onPressed: () => context.pushReplacement(
                        mode.stepPath(id, CollectionRoute.review),
                      ),
                    ),
                  ],
                  SubmitPhase.failed => [
                    const SizedBox(height: LsSpace.xl),
                    _Disc(
                      icon: Icons.cloud_off_outlined,
                      color: LsTint.errorBg,
                    ),
                    const SizedBox(height: LsSpace.md),
                    Text(
                      'Couldn\'t submit',
                      textAlign: TextAlign.center,
                      style: LsText.authTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.failure != null && state.failure!.isConnectivity
                          ? 'We couldn\'t reach the server, so it was not '
                                'submitted. Everything is saved as a draft. '
                                'Try again when you\'re back online.'
                          : '${FailureMessages.generic(state.failure!).body} '
                                'Everything is saved as a draft.',
                      textAlign: TextAlign.center,
                      style: LsText.subtitle,
                    ),
                    const SizedBox(height: LsSpace.lg),
                    LsButton(
                      key: const Key('submit_retry'),
                      label: 'Try again',
                      onPressed: cubit.submit,
                    ),
                    const SizedBox(height: LsSpace.xs),
                    LsButton(
                      label: 'Back to review',
                      variant: LsButtonVariant.secondary,
                      onPressed: () => context.pushReplacement(
                        mode.stepPath(id, CollectionRoute.review),
                      ),
                    ),
                  ],
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _success(BuildContext context, SubmitState state) {
    final s = state.session!;
    final at = state.confirmedAt;
    return [
      const SizedBox(height: LsSpace.xl),
      _Disc(icon: Icons.check, color: AppColors.primary),
      const SizedBox(height: LsSpace.md),
      Text(
        mode.isPatient ? 'Check-in submitted' : 'Session submitted',
        key: const Key('submit_success'),
        textAlign: TextAlign.center,
        style: LsText.authTitle,
      ),
      const SizedBox(height: 6),
      Text(
        'The server confirmed receipt${at == null ? '' : ' at ${LsDates.time(at)}'}. '
        'Thank you, this ${mode.isPatient ? 'check-in' : 'session'} is now '
        'complete.',
        textAlign: TextAlign.center,
        style: LsText.subtitle,
      ),
      const SizedBox(height: LsSpace.lg),
      LsPanel(
        children: [
          if (!mode.isPatient)
            LsKeyValueRow(label: 'Patient', value: s.studyId),
          LsKeyValueRow(label: 'Session ID', value: s.id),
          LsKeyValueRow(label: 'Included', value: _included(s)),
        ],
      ),
      const SizedBox(height: LsSpace.lg),
      LsButton(
        label: mode.isPatient ? 'View my check-in' : 'View submitted session',
        variant: LsButtonVariant.secondary,
        onPressed: () => context.pushReplacement(mode.sessionPath(s.id)),
      ),
      const SizedBox(height: LsSpace.xs),
      if (!mode.isPatient) ...[
        LsButton(
          label: 'Start another collection',
          onPressed: () => context.go(Routes.doctorStartCollection),
        ),
        const SizedBox(height: LsSpace.xs),
      ],
      LsButton(
        key: const Key('submit_done'),
        label: mode.isPatient ? 'Back to home' : 'Back to dashboard',
        variant: mode.isPatient
            ? LsButtonVariant.primary
            : LsButtonVariant.text,
        onPressed: () => context.go(mode.home),
      ),
    ];
  }

  static String _included(CollectionSession s) {
    final parts = [
      if (s.latest(RecordingType.cough) != null) 'cough',
      if (s.latest(RecordingType.breathing) != null) 'breathing',
      if (s.symptoms != null &&
          s.symptoms!.ratedCount == SymptomKey.values.length)
        'symptoms',
      if ((s.summary.notes?.isNotEmpty ?? false) || s.xrays.isNotEmpty)
        'context',
    ];
    if (parts.isEmpty) return '–';
    final text = parts.join(', ');
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 36, color: AppColors.text),
    ),
  );
}
