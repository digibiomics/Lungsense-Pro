import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/entities/recording.dart';

/// Draft / Completed pill (Components.dc.html). [patient] uses the
/// check-in wording ("Not finished", "Submitted").
LsStatusPill sessionPill(SessionStatus s, {bool patient = false}) =>
    switch (s) {
      SessionStatus.draft => LsStatusPill(
        label: patient ? 'Not finished' : 'Draft',
        tone: LsPillTone.pending,
      ),
      SessionStatus.completed => LsStatusPill(
        label: patient ? 'Submitted' : 'Completed',
        tone: LsPillTone.success,
      ),
      SessionStatus.unknown => const LsStatusPill(
        label: 'Status unknown',
        tone: LsPillTone.neutral,
      ),
    };

/// "13.8 s · quality check passed" from the server's recording record.
String recordingNote(AudioRecording r) {
  final d = r.durationSeconds == null
      ? null
      : '${r.durationSeconds!.toStringAsFixed(1)} s';
  final qc = switch (r.qcPassed) {
    true => 'quality check passed',
    false => 'quality check failed',
    null =>
      r.processingFailed ? 'quality check failed' : 'quality check pending',
  };
  return [?d, qc].join(' · ');
}

/// LsCollectionHeader: back to Overview, "Draft saved", and the four
/// labelled step bars (Recorder/Symptoms/Clinical designs). [step] is the
/// current bar, 0–3; bars before it are filled.
class LsCollectionHeader extends StatelessWidget {
  const LsCollectionHeader({
    super.key,
    required this.step,
    required this.onBack,
    this.backLabel = 'Overview',
    this.savedLabel,
  });

  final int step;
  final VoidCallback onBack;
  final String backLabel;

  /// "Draft saved", "Answers saved"; null hides it.
  final String? savedLabel;

  static const labels = ['Cough', 'Breathing', 'Symptoms', 'Context'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, LsSpace.gutter, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left, size: 24),
                label: Text(backLabel),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.text,
                  minimumSize: const Size(LsSize.minTouch, LsSize.minTouch),
                  textStyle: LsText.label.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              if (savedLabel != null)
                Row(
                  children: [
                    const Icon(
                      Icons.cloud_done_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(savedLabel!, style: LsText.helper),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Semantics(
                      label: '${labels[i]}${i == step ? ', current step' : ''}',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: i < step
                                  ? AppColors.primary
                                  : i == step
                                  ? AppColors.supportingGreen
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[i],
                            style: LsText.pill.copyWith(
                              color: i == step
                                  ? AppColors.text
                                  : AppColors.textSecondary,
                              fontWeight: i == step
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum LsStepState { done, todo, missing, optional }

/// LsStepIcon: green check when done, red mark when missing, else the
/// step number on a light disc.
class LsStepIcon extends StatelessWidget {
  const LsStepIcon({super.key, required this.state, required this.number});
  final LsStepState state;
  final int number;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Widget child) = switch (state) {
      LsStepState.done => (
        AppColors.primary,
        const Icon(Icons.check, size: 18, color: AppColors.text),
      ),
      LsStepState.missing => (
        AppColors.error,
        const Icon(Icons.priority_high, size: 18, color: AppColors.surface),
      ),
      _ => (
        AppColors.surface,
        Text(
          '$number',
          style: LsText.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    };
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: state == LsStepState.todo || state == LsStepState.optional
            ? Border.all(color: AppColors.textSecondary, width: 1.5)
            : null,
      ),
      child: child,
    );
  }
}

/// LsStepRow: icon, title, note and an action link (Overview, Review).
class LsStepRow extends StatelessWidget {
  const LsStepRow({
    super.key,
    required this.state,
    required this.number,
    required this.title,
    required this.note,
    this.action,
    this.onAction,
  });

  final LsStepState state;
  final int number;
  final String title;
  final String note;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAction,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            LsStepIcon(state: state, number: number),
            const SizedBox(width: LsSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: LsText.listTitle),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: LsText.helper.copyWith(
                      color: state == LsStepState.missing
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  action!,
                  style: LsText.label.copyWith(
                    color: AppColors.supportingGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// LsSeverityScale: four equal 56px buttons, 0–3, nothing preselected.
class LsSeverityScale extends StatelessWidget {
  const LsSeverityScale({
    super.key,
    required this.value,
    required this.onChanged,
    required this.names,
    this.keyPrefix,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final List<String> names;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final selected = [
      (LsTint.chosen, AppColors.supportingGreen),
      (AppColors.secondary.withValues(alpha: .3), AppColors.text),
      (AppColors.warning.withValues(alpha: .4), AppColors.text),
      (AppColors.error.withValues(alpha: .22), AppColors.error),
    ];
    return Row(
      children: [
        for (var n = 0; n < 4; n++) ...[
          if (n > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              inMutuallyExclusiveGroup: true,
              checked: value == n,
              button: true,
              label: '$n ${names[n]}',
              excludeSemantics: true,
              child: Material(
                color: value == n ? selected[n].$1 : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LsRadius.small),
                  side: BorderSide(
                    color: value == n ? selected[n].$2 : AppColors.border,
                    width: value == n ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  key: keyPrefix == null ? null : Key('${keyPrefix}_$n'),
                  borderRadius: BorderRadius.circular(LsRadius.small),
                  onTap: () => onChanged(n),
                  child: SizedBox(
                    height: LsSize.severityButton,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$n',
                          style: LsText.section.copyWith(
                            fontWeight: value == n
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        Text(
                          names[n],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LsText.pill.copyWith(
                            fontWeight: value == n
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// White card with the patient ID (CollectionOverview, Review).
class PatientIdCard extends StatelessWidget {
  const PatientIdCard({
    super.key,
    required this.label,
    required this.id,
    this.meta,
  });

  final String label;
  final String id;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label,
            style: LsText.helper.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(id, style: LsText.authTitle),
          if (meta != null) ...[
            const SizedBox(height: 4),
            Text(meta!, style: LsText.helper),
          ],
        ],
      ),
    );
  }
}

/// "Session started today, 10:52" / "21 Oct, 15:30".
String startedLabel(SessionSummary s, DateTime now) {
  final t = s.startedAt;
  if (t == null) return 'Session started';
  return LsDates.sameDay(t, now)
      ? 'Session started today, ${LsDates.time(t)}'
      : 'Session started ${LsDates.dayMonth(t)}, ${LsDates.time(t)}';
}

/// Loading / error body for screens that first read the session.
class SessionLoadState extends StatelessWidget {
  const SessionLoadState({
    super.key,
    required this.failure,
    required this.onRetry,
    this.title = 'Couldn\'t load this session.',
  });

  final Failure? failure;
  final VoidCallback onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (failure == null) {
      return const Padding(
        padding: EdgeInsets.all(LsSpace.xl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.supportingGreen),
        ),
      );
    }
    final copy = FailureMessages.generic(failure!);
    return Padding(
      padding: const EdgeInsets.all(LsSpace.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LsBanner(
            tone: LsBannerTone.error,
            title: title,
            body: '${copy.title} ${copy.body}',
          ),
          const SizedBox(height: LsSpace.md),
          LsButton(
            label: 'Try again',
            variant: LsButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
