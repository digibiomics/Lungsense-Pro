import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_sheet.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/symptoms.dart';
import '../../domain/services/draft_visibility.dart';
import '../cubit/collection_session_cubit.dart';
import '../widgets/collection_mode.dart';
import '../widgets/collection_widgets.dart';
import '../widgets/symptom_copy.dart';

/// 17 Collection overview for a draft, or 24 Session detail (read-only)
/// once the server reports the session completed.
class SessionOverviewPage extends StatelessWidget {
  const SessionOverviewPage({super.key, required this.mode, this.now});

  final CollectionMode mode;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionSessionCubit, CollectionSessionState>(
      builder: (context, state) {
        final cubit = context.read<CollectionSessionCubit>();
        final s = state.session;
        if (s == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Session')),
            body: SessionLoadState(failure: state.failure, onRetry: cubit.load),
          );
        }
        final t = now ?? DateTime.now();
        // A draft from an earlier day can't be resumed (same-day rule).
        if (!s.isDraft || DraftVisibility.isExpired(s.summary, t)) {
          return SessionDetailView(session: s, mode: mode);
        }
        return _Overview(session: s, mode: mode, now: t);
      },
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.session,
    required this.mode,
    required this.now,
  });

  final CollectionSession session;
  final CollectionMode mode;
  final DateTime now;

  void _open(BuildContext context, CollectionRoute r) =>
      context.push(mode.stepPath(session.id, r));

  Future<void> _remove(BuildContext context) async {
    final cubit = context.read<CollectionSessionCubit>();
    final r = await showLsSheet<LsConfirmResult>(
      context,
      LsConfirmSheet(
        title: mode.isPatient ? 'Remove this check-in?' : 'Remove this draft?',
        body:
            'It won\'t appear in your lists on this device and can\'t be '
            'resumed. Anything already uploaded stays on the server as an '
            'unfinished ${mode.isPatient ? 'check-in' : 'session'}.',
        confirmLabel: 'Remove',
        variant: LsButtonVariant.destructive,
        confirmKey: const Key('overview_remove_confirm'),
      ),
    );
    if (r == null || !context.mounted) return;
    await cubit.removeDraft();
    if (context.mounted) context.go(mode.home);
  }

  @override
  Widget build(BuildContext context) {
    final s = session;
    final done = 3 - s.missing.length;
    final next = s.missing.isEmpty ? null : s.missing.first;
    final saved = s.summary.updatedAt;

    LsStepState recState(RecordingType t, CollectionStep step) {
      final r = s.latest(t);
      if (r != null && (r.qcPassed == false || r.processingFailed)) {
        return LsStepState.missing;
      }
      return s.isDone(step) ? LsStepState.done : LsStepState.todo;
    }

    String recNote(RecordingType t) {
      final r = s.latest(t);
      if (r == null) return 'Required · ${t.min}–${t.max} s';
      return recordingNote(r);
    }

    final symptoms = s.symptoms;
    final hasContext =
        (s.summary.notes?.trim().isNotEmpty ?? false) || s.xrays.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.chevron_left, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      saved == null ? '' : 'Draft saved ${LsDates.time(saved)}',
                      style: LsText.helper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  LsLinkButton(
                    key: const Key('overview_exit'),
                    label: 'Save & exit',
                    onPressed: () => context.go(mode.home),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.supportingGreen,
                onRefresh: context.read<CollectionSessionCubit>().load,
                child: ListView(
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
                          ? LsDates.dayHeading(s.summary.startedAt ?? now, now)
                          : s.studyId,
                      meta: startedLabel(s.summary, now),
                    ),
                    const SizedBox(height: LsSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Collection steps',
                            style: LsText.section,
                          ),
                        ),
                        Text('$done of 3 required done', style: LsText.helper),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LsPanel(
                      children: [
                        LsStepRow(
                          key: const Key('step_cough'),
                          state: recState(
                            RecordingType.cough,
                            CollectionStep.cough,
                          ),
                          number: 1,
                          title: 'Cough recording',
                          note: recNote(RecordingType.cough),
                          action: s.latest(RecordingType.cough) == null
                              ? 'Record'
                              : 'View',
                          onAction: () => _open(context, CollectionRoute.cough),
                        ),
                        LsStepRow(
                          key: const Key('step_breathing'),
                          state: recState(
                            RecordingType.breathing,
                            CollectionStep.breathing,
                          ),
                          number: 2,
                          title: 'Breathing recording',
                          note: recNote(RecordingType.breathing),
                          action: s.latest(RecordingType.breathing) == null
                              ? 'Record'
                              : 'View',
                          onAction: () =>
                              _open(context, CollectionRoute.breathing),
                        ),
                        LsStepRow(
                          key: const Key('step_symptoms'),
                          state: s.isDone(CollectionStep.symptoms)
                              ? LsStepState.done
                              : LsStepState.todo,
                          number: 3,
                          title: 'Symptoms',
                          note: symptoms == null
                              ? 'Required · ${SymptomKey.values.length} '
                                    'ratings, about 1 min'
                              : symptomsNote(symptoms),
                          action: symptoms == null ? 'Start' : 'Change',
                          onAction: () =>
                              _open(context, CollectionRoute.symptoms),
                        ),
                        LsStepRow(
                          key: const Key('step_context'),
                          state: hasContext
                              ? LsStepState.done
                              : LsStepState.optional,
                          number: 4,
                          title: 'Clinical context',
                          note: hasContext
                              ? contextNote(s)
                              : 'Optional · notes, X-ray',
                          action: hasContext ? 'Change' : 'Add',
                          onAction: () =>
                              _open(context, CollectionRoute.context),
                        ),
                      ],
                    ),
                    const SizedBox(height: LsSpace.md),
                    Text(
                      mode.isPatient
                          ? 'Each step saves as soon as it\'s done. You can '
                                'leave and finish this check-in later today.'
                          : 'Each step saves as soon as it\'s done. You can '
                                'leave and resume this draft later today.',
                      textAlign: TextAlign.center,
                      style: LsText.helper,
                    ),
                    if (context.read<CollectionSessionCubit>().canRemoveDraft)
                      Center(
                        child: LsLinkButton(
                          key: const Key('overview_remove'),
                          label: mode.isPatient
                              ? 'Remove this check-in'
                              : 'Remove draft',
                          style: LsText.label.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                          onPressed: () => _remove(context),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (next != null) ...[
                    LsButton(
                      key: const Key('overview_continue'),
                      label: 'Continue to ${_stepWord(next)}',
                      onPressed: () => _open(context, _routeFor(next)),
                    ),
                    const SizedBox(height: LsSpace.xs),
                  ],
                  LsButton(
                    key: const Key('overview_review'),
                    label: 'Review session',
                    variant: next == null
                        ? LsButtonVariant.primary
                        : LsButtonVariant.secondary,
                    onPressed: () => _open(context, CollectionRoute.review),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _stepWord(CollectionStep s) => switch (s) {
    CollectionStep.cough => 'cough',
    CollectionStep.breathing => 'breathing',
    CollectionStep.symptoms => 'symptoms',
  };

  static CollectionRoute _routeFor(CollectionStep s) => switch (s) {
    CollectionStep.cough => CollectionRoute.cough,
    CollectionStep.breathing => CollectionRoute.breathing,
    CollectionStep.symptoms => CollectionRoute.symptoms,
  };
}

/// "10 of 10 rated · highest: 2 Moderate".
String symptomsNote(SymptomRatings r) {
  final total = SymptomKey.values.length;
  final h = r.highest;
  return [
    '${r.ratedCount} of $total rated',
    if (h != null) 'highest: ${ratingLabel(h)}',
  ].join(' · ');
}

/// "Notes added · 1 X-ray" / "No notes · no X-ray".
String contextNote(CollectionSession s) {
  final notes = (s.summary.notes?.trim().isNotEmpty ?? false)
      ? 'Notes added'
      : 'No notes';
  final n = s.xrays.where((x) => x.isUploaded).length;
  final x = n == 0 ? 'no X-ray' : (n == 1 ? '1 X-ray' : '$n X-rays');
  return '$notes · $x';
}

/// 24 Session detail (read-only, lock icon, no edit actions).
class SessionDetailView extends StatelessWidget {
  const SessionDetailView({
    super.key,
    required this.session,
    required this.mode,
  });

  final CollectionSession session;
  final CollectionMode mode;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final t = s.summary.completedAt ?? s.summary.startedAt;
    final cough = s.latest(RecordingType.cough);
    final breathing = s.latest(RecordingType.breathing);
    final symptoms = s.symptoms;
    final xrays = s.xrays.where((x) => x.isUploaded).toList();
    final notes = s.summary.notes?.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Session details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LsSpace.gutter,
          LsSpace.xs,
          LsSpace.gutter,
          LsSpace.xl,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mode.isPatient
                      ? 'Check-in${t == null ? '' : ' · ${LsDates.dayMonth(t)}'}'
                      : '${s.studyId}${t == null ? '' : ' · ${LsDates.dayMonth(t)}'}',
                  style: LsText.screenTitle,
                ),
              ),
              sessionPill(s.summary.status, patient: mode.isPatient),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  s.isCompleted
                      ? 'Submitted '
                            '${s.summary.completedAt == null ? '' : '${LsDates.dayMonthYear(s.summary.completedAt!)}, ${LsDates.time(s.summary.completedAt!)} '}'
                            '· read-only'
                      : 'This session can\'t be edited in the app.',
                  style: LsText.helper,
                ),
              ),
            ],
          ),
          const SizedBox(height: LsSpace.lg),
          Text('Recordings', style: LsText.section),
          const SizedBox(height: 10),
          LsPanel(
            children: [
              LsKeyValueRow(
                label: 'Cough',
                value: cough == null ? 'Not recorded' : recordingNote(cough),
              ),
              LsKeyValueRow(
                label: 'Breathing',
                value: breathing == null
                    ? 'Not recorded'
                    : recordingNote(breathing),
              ),
            ],
          ),
          const SizedBox(height: LsSpace.lg),
          Text('Symptoms', style: LsText.section),
          const SizedBox(height: 10),
          if (symptoms == null)
            Text('No symptoms recorded.', style: LsText.helper)
          else
            LsPanel(
              children: [
                for (final k in SymptomKey.values)
                  LsKeyValueRow(
                    label: symptomCopy[k]!.title,
                    value: symptoms[k] == null
                        ? 'Not rated'
                        : ratingLabel(symptoms[k]!),
                  ),
              ],
            ),
          const SizedBox(height: LsSpace.lg),
          Text('Clinical context', style: LsText.section),
          const SizedBox(height: 10),
          LsPanel(
            children: [
              LsKeyValueRow(
                label: 'Notes',
                value: notes == null || notes.isEmpty ? 'None' : notes,
              ),
              for (final x in xrays)
                _XrayRow(
                  xray: x,
                  onView: () async {
                    final ok = await context
                        .read<CollectionSessionCubit>()
                        .openXray(x.id);
                    if (!ok && context.mounted) {
                      showLsToast(context, 'Couldn\'t open the X-ray.');
                    }
                  },
                ),
              if (xrays.isEmpty)
                const LsKeyValueRow(label: 'Chest X-ray', value: 'None'),
            ],
          ),
          if (!mode.isPatient) ...[
            const SizedBox(height: LsSpace.lg),
            Text(
              'Session ID ${s.id}',
              style: LsText.footnote,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _XrayRow extends StatelessWidget {
  const _XrayRow({required this.xray, required this.onView});
  final XrayImage xray;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final meta = [
      ?xray.view?.label,
      if (xray.uploadedAt != null) 'Uploaded ${LsDates.time(xray.uploadedAt!)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LsTint.iconDisc,
              borderRadius: BorderRadius.circular(LsRadius.small),
            ),
            child: const Icon(Icons.image_outlined, size: 20),
          ),
          const SizedBox(width: LsSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  xray.fileName ?? 'Chest X-ray',
                  style: LsText.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.isNotEmpty) Text(meta, style: LsText.helper),
              ],
            ),
          ),
          LsLinkButton(label: 'View', onPressed: onView),
        ],
      ),
    );
  }
}
