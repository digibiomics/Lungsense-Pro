import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/services/device_services.dart';
import 'collection_events.dart';

/// LsRecorder states (Recorder.dc.html script), plus the app-side states
/// the design leaves implicit: loading the session, microphone refused, and
/// a quality check that has not finished after polling.
enum RecorderPhase {
  loading,
  loadFailed,
  idle,
  micDenied,
  recording,
  tooShort,
  importInvalid,
  uploading,
  checking,
  passed,
  qualityFailed,
  checkPending,
  uploadFailed,
}

class RecorderState extends Equatable {
  const RecorderState({
    this.phase = RecorderPhase.loading,
    this.session,
    this.elapsed = Duration.zero,
    this.level = 0,
    this.progress = 0,
    this.recording,
    this.file,
    this.fromFile = false,
    this.failure,
    this.playing = false,
  });

  final RecorderPhase phase;
  final CollectionSession? session;

  /// Recorded or imported length (live while recording).
  final Duration elapsed;

  /// Mic level 0–1 while recording.
  final double level;

  /// Upload progress 0–1.
  final double progress;

  /// The server's record of the current recording.
  final AudioRecording? recording;

  /// The local file of the current attempt (kept for Retry upload).
  final LocalFile? file;
  final bool fromFile;
  final Failure? failure;
  final bool playing;

  /// Continue is enabled only once the server reports the quality check
  /// passed. [RecorderPhase.checkPending] also allows it: the upload is
  /// confirmed and the result shows on the overview later (KI-20).
  bool get canContinue =>
      phase == RecorderPhase.passed || phase == RecorderPhase.checkPending;

  bool get hasTake => switch (phase) {
    RecorderPhase.uploading ||
    RecorderPhase.checking ||
    RecorderPhase.passed ||
    RecorderPhase.qualityFailed ||
    RecorderPhase.checkPending ||
    RecorderPhase.uploadFailed => true,
    _ => false,
  };

  bool get busy =>
      phase == RecorderPhase.uploading || phase == RecorderPhase.checking;

  RecorderState copyWith({
    RecorderPhase? phase,
    CollectionSession? session,
    Duration? elapsed,
    double? level,
    double? progress,
    AudioRecording? Function()? recording,
    LocalFile? Function()? file,
    bool? fromFile,
    Failure? Function()? failure,
    bool? playing,
  }) => RecorderState(
    phase: phase ?? this.phase,
    session: session ?? this.session,
    elapsed: elapsed ?? this.elapsed,
    level: level ?? this.level,
    progress: progress ?? this.progress,
    recording: recording != null ? recording() : this.recording,
    file: file != null ? file() : this.file,
    fromFile: fromFile ?? this.fromFile,
    failure: failure != null ? failure() : this.failure,
    playing: playing ?? this.playing,
  );

  @override
  List<Object?> get props => [
    phase,
    session,
    elapsed,
    level,
    progress,
    recording,
    file,
    fromFile,
    failure?.kind,
    failure?.message,
    playing,
  ];
}

/// One recorder for cough and breathing ([type] sets the limits).
///
/// idle → recording → (stop < min) tooShort | (stop ≥ min, auto-stop at
/// max) uploading → checking → passed | qualityFailed; upload error →
/// uploadFailed (Retry). Imported files outside min–max → importInvalid.
class RecorderCubit extends Cubit<RecorderState> {
  RecorderCubit({
    required CollectionRepository repository,
    required this._capture,
    required this._inspector,
    required this._playback,
    required this._files,
    required this.sessionId,
    this.events,
    required this.type,
    this.tick = const Duration(milliseconds: 100),
    this.pollInterval = const Duration(seconds: 2),
    this.pollAttempts = 10,
  }) : _repo = repository,
       super(const RecorderState()) {
    _playingSub = _playback.playing.listen((p) {
      if (!isClosed && p != state.playing) emit(state.copyWith(playing: p));
    });
  }

  final CollectionRepository _repo;
  final AudioCapture _capture;
  final AudioInspector _inspector;
  final AudioPlayback _playback;
  final FilePicking _files;
  final String sessionId;
  final RecordingType type;
  final CollectionEvents? events;
  final Duration tick;
  final Duration pollInterval;
  final int pollAttempts;

  Timer? _ticker;
  StreamSubscription<double>? _levelSub;
  StreamSubscription<bool>? _playingSub;

  /// Recordings to remove once a newer one of this type passes.
  final Set<String> _superseded = {};
  int _pollGeneration = 0;

  Future<void> load() async {
    emit(state.copyWith(phase: RecorderPhase.loading, failure: () => null));
    try {
      final s = await _repo.getSession(sessionId);
      if (isClosed) return;
      final existing = s.latest(type);
      emit(
        state.copyWith(
          session: s,
          phase: RecorderPhase.idle,
          recording: () => existing,
          elapsed: existing?.durationSeconds == null
              ? Duration.zero
              : Duration(
                  milliseconds: (existing!.durationSeconds! * 1000).round(),
                ),
        ),
      );
      if (existing != null) _applyResult(existing, fresh: false);
    } on Failure catch (f) {
      if (!isClosed) {
        emit(state.copyWith(phase: RecorderPhase.loadFailed, failure: () => f));
      }
    }
  }

  /// The big button: starts, or stops while recording.
  Future<void> toggleRecord() async {
    if (state.phase == RecorderPhase.recording) return stop();
    if (state.busy) return;
    await _playback.stop();
    if (!await _capture.ensurePermission()) {
      if (!isClosed) emit(state.copyWith(phase: RecorderPhase.micDenied));
      return;
    }
    try {
      await _capture.start();
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: RecorderPhase.micDenied,
            failure: () => const Failure(
              kind: FailureKind.unknown,
              message: 'The microphone could not be started.',
            ),
          ),
        );
      }
      return;
    }
    if (isClosed) return;
    _supersedeCurrent();
    emit(
      state.copyWith(
        phase: RecorderPhase.recording,
        elapsed: Duration.zero,
        level: 0,
        fromFile: false,
        file: () => null,
        recording: () => null,
        failure: () => null,
      ),
    );
    _levelSub = _capture.level.listen((l) {
      if (!isClosed && state.phase == RecorderPhase.recording) {
        emit(state.copyWith(level: l));
      }
    });
    _ticker = Timer.periodic(tick, (_) {
      if (isClosed || state.phase != RecorderPhase.recording) return;
      final next = state.elapsed + tick;
      if (next >= type.maxDuration) {
        emit(state.copyWith(elapsed: type.maxDuration));
        _finish();
      } else {
        emit(state.copyWith(elapsed: next));
      }
    });
  }

  Future<void> stop() async {
    if (state.phase != RecorderPhase.recording) return;
    if (state.elapsed < type.minDuration) {
      _stopTimers();
      await _capture.cancel();
      if (!isClosed) {
        emit(state.copyWith(phase: RecorderPhase.tooShort, level: 0));
      }
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    _stopTimers();
    final file = await _capture.stop();
    if (isClosed) return;
    if (file == null) {
      emit(
        state.copyWith(
          phase: RecorderPhase.idle,
          level: 0,
          failure: () => const Failure(
            kind: FailureKind.unknown,
            message: 'The recording could not be saved on this phone.',
          ),
        ),
      );
      return;
    }
    emit(state.copyWith(file: () => file, level: 0));
    await _upload(file);
  }

  /// "Import an audio file instead": checks the length before uploading.
  Future<void> importFile() async {
    if (state.busy || state.phase == RecorderPhase.recording) return;
    await _playback.stop();
    final file = await _files.pickAudio();
    if (file == null || isClosed) return;
    final d = await _inspector.durationOf(file);
    if (isClosed) return;
    if (d == null || d < type.minDuration || d > type.maxDuration) {
      emit(
        state.copyWith(
          phase: RecorderPhase.importInvalid,
          elapsed: d ?? Duration.zero,
          fromFile: true,
          file: () => null,
          failure: () => null,
        ),
      );
      return;
    }
    _supersedeCurrent();
    emit(
      state.copyWith(
        elapsed: d,
        fromFile: true,
        file: () => file,
        recording: () => null,
      ),
    );
    await _upload(file);
  }

  Future<void> retryUpload() async {
    final f = state.file;
    if (f != null && state.phase == RecorderPhase.uploadFailed) {
      await _upload(f);
    }
  }

  /// "Redo" / "Record again": back to idle. A recording that failed the
  /// quality check is removed from the session; a passed one stays until a
  /// new recording passes.
  Future<void> rerecord() async {
    if (state.busy || state.phase == RecorderPhase.recording) return;
    await _playback.stop();
    final r = state.recording;
    if (r != null && (r.qcPassed == false || r.processingFailed)) {
      unawaited(_deleteQuietly(r.id));
    } else if (r != null) {
      _superseded.add(r.id);
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          phase: RecorderPhase.idle,
          elapsed: Duration.zero,
          recording: () => null,
          file: () => null,
          fromFile: false,
          failure: () => null,
        ),
      );
    }
  }

  Future<void> checkAgain() async {
    final r = state.recording;
    if (r == null || state.phase != RecorderPhase.checkPending) return;
    emit(state.copyWith(phase: RecorderPhase.checking));
    unawaited(_poll(r.id));
  }

  Future<void> togglePlay() async {
    if (state.playing) return _playback.stop();
    if (state.busy || state.phase == RecorderPhase.recording) return;
    try {
      final f = state.file;
      if (f != null) {
        await _playback.playFile(f.path);
      } else if (state.recording != null) {
        await _playback.playUrl(
          await _repo.audioDownloadUrl(state.recording!.id),
        );
      }
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(failure: () => f));
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            failure: () => const Failure(
              kind: FailureKind.unknown,
              message: 'This recording can\'t be played on this phone.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _upload(LocalFile file) async {
    emit(
      state.copyWith(
        phase: RecorderPhase.uploading,
        progress: 0,
        failure: () => null,
      ),
    );
    try {
      final rec = await _repo.uploadAudio(
        sessionId,
        type,
        file,
        onProgress: (p) {
          if (!isClosed && state.phase == RecorderPhase.uploading) {
            emit(state.copyWith(progress: p));
          }
        },
      );
      events?.changed(sessionId);
      if (isClosed) return;
      emit(state.copyWith(progress: 1, recording: () => rec));
      _applyResult(rec, fresh: true);
    } on Failure catch (f) {
      if (!isClosed) {
        emit(
          state.copyWith(phase: RecorderPhase.uploadFailed, failure: () => f),
        );
      }
    }
  }

  void _applyResult(AudioRecording r, {required bool fresh}) {
    if (isClosed) return;
    if (r.qcPassed == true) {
      emit(state.copyWith(phase: RecorderPhase.passed, recording: () => r));
      if (fresh) _removeSuperseded(r.id);
    } else if (r.qcPassed == false || r.processingFailed) {
      emit(
        state.copyWith(phase: RecorderPhase.qualityFailed, recording: () => r),
      );
    } else {
      emit(state.copyWith(phase: RecorderPhase.checking, recording: () => r));
      unawaited(_poll(r.id, fresh: fresh));
    }
  }

  Future<void> _poll(String id, {bool fresh = true}) async {
    final gen = ++_pollGeneration;
    for (var i = 0; i < pollAttempts; i++) {
      await Future<void>.delayed(pollInterval);
      if (isClosed || gen != _pollGeneration) return;
      if (state.phase != RecorderPhase.checking) return;
      try {
        final r = await _repo.getAudio(id);
        if (isClosed || gen != _pollGeneration) return;
        if (r.qcPassed != null || r.processingFailed) {
          events?.changed(sessionId);
          return _applyResult(r, fresh: fresh);
        }
        emit(state.copyWith(recording: () => r));
      } on Failure {
        // Keep polling; the upload itself is confirmed.
      }
    }
    if (!isClosed && gen == _pollGeneration) {
      emit(state.copyWith(phase: RecorderPhase.checkPending));
    }
  }

  void _supersedeCurrent() {
    final r = state.recording;
    if (r != null && r.qcPassed != false && !r.processingFailed) {
      _superseded.add(r.id);
    }
  }

  void _removeSuperseded(String keepId) {
    final ids = {
      ..._superseded,
      for (final r in state.session?.recordings ?? const <AudioRecording>[])
        if (r.type == type) r.id,
    }..remove(keepId);
    _superseded.clear();
    for (final id in ids) {
      unawaited(_deleteQuietly(id));
    }
  }

  Future<void> _deleteQuietly(String id) async {
    try {
      await _repo.deleteAudio(id);
      events?.changed(sessionId);
    } on Failure {
      // Best effort: an extra recording does not block completion.
    }
  }

  void _stopTimers() {
    _ticker?.cancel();
    _ticker = null;
    _levelSub?.cancel();
    _levelSub = null;
  }

  @override
  Future<void> close() async {
    _stopTimers();
    _pollGeneration++;
    await _playingSub?.cancel();
    if (state.phase == RecorderPhase.recording) await _capture.cancel();
    await _playback.stop();
    return super.close();
  }
}
