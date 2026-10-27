import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../domain/entities/recording.dart';
import '../cubit/recorder_cubit.dart';
import '../widgets/collection_mode.dart';
import '../widgets/collection_widgets.dart';

/// 18 Cough / 19 Breathing: LsRecorder (Recorder.dc.html).
class RecorderPage extends StatelessWidget {
  const RecorderPage({super.key, required this.type, required this.mode});

  final RecordingType type;
  final CollectionMode mode;

  static const _tips = {
    (RecordingType.cough, false): [
      'Ask for 3 to 5 deliberate, separate coughs.',
      'Hold the phone 15–20 cm from the patient\'s mouth.',
      'Turn off fans or TV; keep the room quiet.',
    ],
    (RecordingType.cough, true): [
      'Give 3 to 5 deliberate, separate coughs.',
      'Hold your phone 15–20 cm from your mouth.',
      'Turn off fans or TV; find a quiet room.',
    ],
    (RecordingType.breathing, false): [
      'Ask the patient to take slow, steady, deep breaths through the '
          'mouth.',
      'Hold the phone near the mouth, or against the chest as in the '
          'protocol.',
      'Keep the room quiet; no talking during recording.',
    ],
    (RecordingType.breathing, true): [
      'Take slow, steady, deep breaths through your mouth.',
      'Hold your phone near your mouth, or against your chest.',
      'Find a quiet room; don\'t talk while recording.',
    ],
  };

  CollectionRoute get _next => type == RecordingType.cough
      ? CollectionRoute.breathing
      : CollectionRoute.symptoms;

  String get _nextLabel =>
      type == RecordingType.cough ? 'breathing' : 'symptoms';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecorderCubit, RecorderState>(
      builder: (context, state) {
        final cubit = context.read<RecorderCubit>();
        final session = state.session;
        return PopScope(
          canPop: state.phase != RecorderPhase.recording && !state.busy,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LsCollectionHeader(
                    step: type == RecordingType.cough ? 0 : 1,
                    savedLabel: state.phase == RecorderPhase.passed
                        ? 'Draft saved'
                        : null,
                    onBack: () {
                      if (state.phase == RecorderPhase.recording ||
                          state.busy) {
                        return;
                      }
                      context.pop();
                    },
                  ),
                  Expanded(
                    child: switch (state.phase) {
                      RecorderPhase.loading => const SessionLoadState(
                        failure: null,
                        onRetry: _noop,
                      ),
                      RecorderPhase.loadFailed => SessionLoadState(
                        failure: state.failure,
                        onRetry: cubit.load,
                      ),
                      _ => ListView(
                        padding: const EdgeInsets.fromLTRB(
                          LsSpace.gutter,
                          LsSpace.xs,
                          LsSpace.gutter,
                          LsSpace.lg,
                        ),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    '${type.label} recording',
                                    style: LsText.screenTitle,
                                  ),
                                ),
                              ),
                              _Chip('${type.min}–${type.max} s'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.isPatient
                                ? 'Your check-in · today'
                                : 'Patient ${session?.studyId ?? ''} · '
                                      '${startedLabel(session!.summary, DateTime.now()).replaceFirst('Session started', 'session started')}',
                            style: LsText.helper,
                          ),
                          if (!state.hasTake &&
                              state.phase != RecorderPhase.recording) ...[
                            const SizedBox(height: LsSpace.md),
                            _Tips(_tips[(type, mode.isPatient)]!),
                          ],
                          const SizedBox(height: LsSpace.lg),
                          _TimerBlock(state: state, type: type),
                          const SizedBox(height: LsSpace.lg),
                          if (state.hasTake)
                            _Playback(state: state, cubit: cubit)
                          else
                            _RecordButton(state: state, cubit: cubit),
                          if (!state.hasTake &&
                              state.phase != RecorderPhase.recording) ...[
                            const SizedBox(height: LsSpace.xs),
                            Center(
                              child: LsLinkButton(
                                key: const Key('rec_import'),
                                label: 'Import an audio file instead',
                                onPressed: cubit.importFile,
                              ),
                            ),
                          ],
                          const SizedBox(height: LsSpace.md),
                          ?_message(state, cubit),
                        ],
                      ),
                    },
                  ),
                  if (state.phase != RecorderPhase.loading &&
                      state.phase != RecorderPhase.loadFailed)
                    _Bottom(
                      state: state,
                      nextLabel: _nextLabel,
                      onContinue: () => context.pushReplacement(
                        mode.stepPath(cubit.sessionId, _next),
                      ),
                      type: type,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void _noop() {}

  Widget? _message(RecorderState s, RecorderCubit cubit) {
    final secs = (s.elapsed.inMilliseconds / 1000).toStringAsFixed(1);
    final failureText = s.failure == null
        ? null
        : (s.failure!.message ?? FailureMessages.generic(s.failure!).body);
    return switch (s.phase) {
      RecorderPhase.tooShort => LsBanner(
        tone: LsBannerTone.warning,
        title: 'Recording too short ($secs s).',
        body:
            '${type.label} recordings need at least ${type.min} seconds. '
            'Tap the button to record again.',
      ),
      RecorderPhase.importInvalid => LsBanner(
        tone: LsBannerTone.error,
        title: s.elapsed == Duration.zero
            ? 'This file can\'t be read as audio.'
            : 'This file is ${s.elapsed.inSeconds} s long.',
        body:
            '${type.label} files must be ${type.min}–${type.max} s. Record '
            'now, or choose a shorter file.',
      ),
      RecorderPhase.uploading => _ProgressBanner(progress: s.progress),
      RecorderPhase.checking => const LsBanner(
        tone: LsBannerTone.info,
        title: 'Uploaded.',
        body: 'Checking recording quality…',
      ),
      RecorderPhase.passed => const LsBanner(
        tone: LsBannerTone.success,
        title: 'Saved and quality check passed.',
        body: 'Play it back if you want, then continue.',
      ),
      RecorderPhase.qualityFailed => LsBanner(
        tone: LsBannerTone.error,
        title: 'Quality check failed.',
        body:
            '${s.recording?.qcReason ?? 'The server couldn\'t check this recording.'} '
            'Please record again.',
      ),
      RecorderPhase.checkPending => LsBanner(
        tone: LsBannerTone.info,
        title: 'Uploaded. The quality check is still running.',
        body:
            'You can continue; the result shows on the overview when it is '
            'ready.',
        actionLabel: 'Check again',
        onAction: cubit.checkAgain,
      ),
      RecorderPhase.uploadFailed => LsBanner(
        tone: LsBannerTone.error,
        title: 'Upload failed.',
        body:
            'The recording is kept on this phone. '
            '${failureText ?? 'Check your connection.'}',
        actionLabel: 'Retry upload',
        onAction: cubit.retryUpload,
      ),
      RecorderPhase.micDenied => LsBanner(
        tone: LsBannerTone.warning,
        title: 'Microphone not available.',
        body:
            failureText ??
            'Allow microphone access for LungSense Pro in your phone\'s '
                'settings, or import an audio file instead.',
      ),
      _ when failureText != null => LsBanner(
        tone: LsBannerTone.error,
        title: 'Something went wrong.',
        body: failureText,
      ),
      _ => null,
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: LsTint.iconDisc,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: LsText.pill),
  );
}

class _Tips extends StatelessWidget {
  const _Tips(this.tips);
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return LsNote(
      bordered: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: 8),
                    child: Icon(Icons.circle, size: 6),
                  ),
                  Expanded(child: Text(t)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _clock(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

class _TimerBlock extends StatelessWidget {
  const _TimerBlock({required this.state, required this.type});
  final RecorderState state;
  final RecordingType type;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final (String label, Color bg, Color dot) = switch (s.phase) {
      RecorderPhase.recording => ('Recording', LsTint.errorBg, AppColors.error),
      RecorderPhase.tooShort => (
        'Too short',
        LsTint.draftPill,
        AppColors.warning,
      ),
      RecorderPhase.importInvalid => (
        'File not accepted',
        LsTint.errorBg,
        AppColors.error,
      ),
      RecorderPhase.uploading => (
        'Uploading',
        AppColors.info.withValues(alpha: .12),
        AppColors.info,
      ),
      RecorderPhase.checking || RecorderPhase.checkPending => (
        'Checking quality',
        AppColors.info.withValues(alpha: .12),
        AppColors.info,
      ),
      RecorderPhase.passed => (
        'Saved · quality passed',
        LsTint.completedPill,
        AppColors.success,
      ),
      RecorderPhase.qualityFailed => (
        'Quality check failed',
        LsTint.errorBg,
        AppColors.error,
      ),
      RecorderPhase.uploadFailed => (
        'Upload failed',
        LsTint.errorBg,
        AppColors.error,
      ),
      _ => ('Ready to record', AppColors.background, AppColors.textSecondary),
    };
    final max = type.maxDuration.inMilliseconds;
    final shown = s.phase == RecorderPhase.importInvalid
        ? s.elapsed
        : (s.elapsed > type.maxDuration ? type.maxDuration : s.elapsed);
    final fill = (shown.inMilliseconds / max).clamp(0.0, 1.0);
    final minFrac = type.minDuration.inMilliseconds / max;
    final fillColor = s.phase == RecorderPhase.importInvalid
        ? AppColors.error
        : s.elapsed >= type.minDuration
        ? AppColors.primary
        : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(LsRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 24,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      key: const Key('rec_status'),
                      style: LsText.pill,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Semantics(
                liveRegion: s.phase != RecorderPhase.recording,
                child: Text(_clock(shown), style: LsText.timer),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ ${_clock(type.maxDuration)}',
                  style: LsText.helper,
                ),
              ),
            ],
          ),
          const SizedBox(height: LsSpace.sm),
          LayoutBuilder(
            builder: (context, c) => SizedBox(
              height: 14,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 3,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 3,
                    child: Container(
                      height: 8,
                      width: c.maxWidth * fill,
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: c.maxWidth * minFrac - 1,
                    top: 0,
                    child: Container(
                      width: 2,
                      height: 14,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, c) => SizedBox(
              height: 18,
              child: Stack(
                children: [
                  Text('0 s', style: LsText.footnote),
                  Positioned(
                    left: (c.maxWidth * minFrac - 24).clamp(0, c.maxWidth),
                    child: Text('min ${type.min} s', style: LsText.footnote),
                  ),
                  Positioned(
                    right: 0,
                    child: Text('${type.max} s', style: LsText.footnote),
                  ),
                ],
              ),
            ),
          ),
          if (s.phase == RecorderPhase.recording) ...[
            const SizedBox(height: LsSpace.sm),
            _LevelMeter(level: s.level),
          ],
        ],
      ),
    );
  }
}

class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level});
  final double level;

  @override
  Widget build(BuildContext context) {
    const bars = 16;
    return Semantics(
      label: 'Mic level',
      excludeSemantics: true,
      child: Row(
        children: [
          Text('Mic level', style: LsText.helper),
          const SizedBox(width: LsSpace.sm),
          Expanded(
            child: SizedBox(
              height: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < bars; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: Container(
                        height: i / bars < level ? 6 + 14 * (i / bars) : 3,
                        decoration: BoxDecoration(
                          color: i / bars > .85
                              ? AppColors.warning
                              : i / bars < level
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.state, required this.cubit});
  final RecorderState state;
  final RecorderCubit cubit;

  @override
  Widget build(BuildContext context) {
    final recording = state.phase == RecorderPhase.recording;
    final label = recording
        ? 'Tap to stop'
        : (state.phase == RecorderPhase.tooShort ||
              state.phase == RecorderPhase.importInvalid)
        ? 'Record again'
        : 'Tap to record';
    return Column(
      children: [
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: recording ? AppColors.error : AppColors.primary,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: AppColors.text.withValues(alpha: .3),
            child: InkWell(
              key: const Key('rec_button'),
              customBorder: const CircleBorder(),
              onTap: cubit.toggleRecord,
              child: SizedBox.square(
                dimension: LsSize.recordButton,
                child: Icon(
                  recording ? Icons.stop_rounded : Icons.mic_none_rounded,
                  size: 36,
                  color: recording ? AppColors.surface : AppColors.text,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: LsSpace.xs),
        Text(label, style: LsText.label),
      ],
    );
  }
}

class _Playback extends StatelessWidget {
  const _Playback({required this.state, required this.cubit});
  final RecorderState state;
  final RecorderCubit cubit;

  @override
  Widget build(BuildContext context) {
    final secs = (state.elapsed.inMilliseconds / 1000).toStringAsFixed(1);
    final source = state.fromFile ? 'Imported file' : 'Recording';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(LsRadius.panel),
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.secondary,
            shape: const CircleBorder(),
            child: IconButton(
              key: const Key('rec_play'),
              tooltip: state.playing ? 'Pause playback' : 'Play recording',
              onPressed: state.busy ? null : cubit.togglePlay,
              icon: Icon(
                state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: LsSpace.sm),
          Expanded(
            child: Text(
              state.elapsed == Duration.zero ? source : '$source · $secs s',
              style: LsText.label,
            ),
          ),
          TextButton.icon(
            key: const Key('rec_redo'),
            onPressed: state.busy ? null : cubit.rerecord,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Redo'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.text,
              minimumSize: const Size(LsSize.minTouch, LsSize.minTouch),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(LsRadius.control),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Uploading… $pct%',
              style: LsText.bannerBody.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: AppColors.info,
                backgroundColor: AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({
    required this.state,
    required this.nextLabel,
    required this.onContinue,
    required this.type,
  });

  final RecorderState state;
  final String nextLabel;
  final VoidCallback onContinue;
  final RecordingType type;

  @override
  Widget build(BuildContext context) {
    final reason = switch (state.phase) {
      RecorderPhase.idle || RecorderPhase.tooShort || RecorderPhase.micDenied =>
        'Record at least ${type.min} seconds to continue.',
      RecorderPhase.recording =>
        'Recording stops automatically at ${type.max} s.',
      RecorderPhase.importInvalid =>
        'Add a recording of ${type.min}–${type.max} s to continue.',
      RecorderPhase.uploading => 'Waiting for the upload to finish.',
      RecorderPhase.checking => 'Waiting for the quality check.',
      RecorderPhase.qualityFailed => 'Record again to continue.',
      RecorderPhase.uploadFailed => 'Retry the upload to continue.',
      _ => null,
    };
    return Container(
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
          LsButton(
            key: const Key('rec_continue'),
            label: 'Continue to $nextLabel',
            onPressed: state.canContinue ? onContinue : null,
          ),
          if (reason != null) ...[
            const SizedBox(height: 6),
            Text(reason, textAlign: TextAlign.center, style: LsText.helper),
          ],
        ],
      ),
    );
  }
}
