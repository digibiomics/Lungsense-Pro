import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/symptoms.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/services/device_services.dart';
import 'collection_events.dart';

// ---------------------------------------------------------------- Symptoms

class SymptomsState extends Equatable {
  const SymptomsState({
    this.loading = true,
    this.ratings = SymptomRatings.empty,
    this.tried = false,
    this.saving = false,
    this.saved = false,
    this.failure,
    this.studyId,
  });

  final bool loading;
  final SymptomRatings ratings;

  /// Continue was pressed with unrated items: highlight them.
  final bool tried;
  final bool saving;

  /// The server confirmed the PUT.
  final bool saved;
  final Failure? failure;
  final String? studyId;

  SymptomsState copyWith({
    bool? loading,
    SymptomRatings? ratings,
    bool? tried,
    bool? saving,
    bool? saved,
    Failure? Function()? failure,
    String? studyId,
  }) => SymptomsState(
    loading: loading ?? this.loading,
    ratings: ratings ?? this.ratings,
    tried: tried ?? this.tried,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    failure: failure != null ? failure() : this.failure,
    studyId: studyId ?? this.studyId,
  );

  @override
  List<Object?> get props => [
    loading,
    ratings,
    tried,
    saving,
    saved,
    failure?.kind,
    studyId,
  ];
}

/// 20 Symptoms: ten 0–3 ratings, no preselection, saved with one PUT.
class SymptomsCubit extends Cubit<SymptomsState> {
  SymptomsCubit(this._repo, this.sessionId, {this.events})
    : super(const SymptomsState());

  final CollectionRepository _repo;
  final String sessionId;
  final CollectionEvents? events;

  Future<void> load() async {
    emit(state.copyWith(loading: true, failure: () => null));
    try {
      final saved = await _repo.getSymptoms(sessionId);
      if (isClosed) return;
      emit(
        state.copyWith(loading: false, ratings: saved ?? SymptomRatings.empty),
      );
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(loading: false, failure: () => f));
    }
  }

  void rate(SymptomKey k, int v) {
    if (state.saving) return;
    emit(state.copyWith(ratings: state.ratings.withRating(k, v), saved: false));
  }

  /// Returns true once the server saved all ten ratings.
  Future<bool> submit() async {
    if (state.saving) return false;
    if (!state.ratings.isComplete) {
      emit(state.copyWith(tried: true));
      return false;
    }
    emit(state.copyWith(saving: true, failure: () => null));
    try {
      final r = await _repo.saveSymptoms(sessionId, state.ratings);
      events?.changed(sessionId);
      if (isClosed) return true;
      emit(state.copyWith(saving: false, saved: true, ratings: r));
      return true;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(saving: false, failure: () => f));
      return false;
    }
  }
}

// --------------------------------------------------------- Clinical context

class ClinicalState extends Equatable {
  const ClinicalState({
    this.session,
    this.loadFailure,
    this.saving = false,
    this.saveFailure,
    this.uploading = false,
    this.progress = 0,
    this.xrayFailure,
    this.removingId,
  });

  final CollectionSession? session;
  final Failure? loadFailure;
  final bool saving;
  final Failure? saveFailure;
  final bool uploading;
  final double progress;
  final Failure? xrayFailure;
  final String? removingId;

  List<XrayImage> get xrays =>
      session?.xrays.where((x) => x.isUploaded).toList() ?? const [];

  ClinicalState copyWith({
    CollectionSession? session,
    Failure? Function()? loadFailure,
    bool? saving,
    Failure? Function()? saveFailure,
    bool? uploading,
    double? progress,
    Failure? Function()? xrayFailure,
    String? Function()? removingId,
  }) => ClinicalState(
    session: session ?? this.session,
    loadFailure: loadFailure != null ? loadFailure() : this.loadFailure,
    saving: saving ?? this.saving,
    saveFailure: saveFailure != null ? saveFailure() : this.saveFailure,
    uploading: uploading ?? this.uploading,
    progress: progress ?? this.progress,
    xrayFailure: xrayFailure != null ? xrayFailure() : this.xrayFailure,
    removingId: removingId != null ? removingId() : this.removingId,
  );

  @override
  List<Object?> get props => [
    session,
    loadFailure?.kind,
    saving,
    saveFailure?.kind,
    uploading,
    progress,
    xrayFailure?.kind,
    xrayFailure?.message,
    removingId,
  ];
}

/// 21 Clinical context (optional): notes and chest X-rays.
///
/// The design's "Known diagnosis" picker is not here: the Pro API has no
/// diagnosis field or option list (KNOWN_ISSUES KI-18).
class ClinicalCubit extends Cubit<ClinicalState> {
  ClinicalCubit(this._repo, this._files, this.sessionId, {this.events})
    : super(const ClinicalState());

  final CollectionRepository _repo;
  final FilePicking _files;
  final String sessionId;
  final CollectionEvents? events;

  static const maxNotes = 2000;

  Future<void> load() async {
    emit(state.copyWith(loadFailure: () => null));
    try {
      final s = await _repo.getSession(sessionId);
      if (!isClosed) emit(state.copyWith(session: s));
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(loadFailure: () => f));
    }
  }

  /// Saves the notes if they changed. True once the server confirmed.
  Future<bool> save(String notes) async {
    final s = state.session;
    if (s == null || state.saving || state.uploading) return false;
    final trimmed = notes.trim();
    if (trimmed == (s.summary.notes ?? '').trim()) return true;
    emit(state.copyWith(saving: true, saveFailure: () => null));
    try {
      final updated = await _repo.updateNotes(sessionId, trimmed);
      events?.changed(sessionId);
      if (!isClosed) emit(state.copyWith(saving: false, session: updated));
      return true;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(saving: false, saveFailure: () => f));
      return false;
    }
  }

  Future<void> attachXray({XrayView? view, DateTime? takenOn}) async {
    if (state.uploading) return;
    final file = await _files.pickXray();
    if (file == null || isClosed) return;
    emit(state.copyWith(uploading: true, progress: 0, xrayFailure: () => null));
    try {
      await _repo.uploadXray(
        sessionId,
        file,
        view: view,
        takenOn: takenOn,
        onProgress: (p) {
          if (!isClosed) emit(state.copyWith(progress: p));
        },
      );
      events?.changed(sessionId);
      final s = await _repo.getSession(sessionId);
      if (!isClosed) emit(state.copyWith(uploading: false, session: s));
    } on Failure catch (f) {
      if (!isClosed) {
        emit(state.copyWith(uploading: false, xrayFailure: () => f));
      }
    }
  }

  Future<void> removeXray(XrayImage x) async {
    if (state.removingId != null) return;
    emit(state.copyWith(removingId: () => x.id, xrayFailure: () => null));
    try {
      await _repo.deleteXray(x.id);
      events?.changed(sessionId);
      final s = await _repo.getSession(sessionId);
      if (!isClosed) emit(state.copyWith(removingId: () => null, session: s));
    } on Failure catch (f) {
      if (!isClosed) {
        emit(state.copyWith(removingId: () => null, xrayFailure: () => f));
      }
    }
  }
}

// ------------------------------------------------------------------ Submit

enum SubmitPhase { submitting, success, missing, failed }

class SubmitState extends Equatable {
  const SubmitState({
    this.phase = SubmitPhase.submitting,
    this.session,
    this.missing = const [],
    this.failure,
    this.confirmedAt,
  });

  final SubmitPhase phase;
  final CollectionSession? session;
  final List<CollectionStep> missing;
  final Failure? failure;

  /// Local time the 200 arrived ("The server confirmed receipt at 11:06").
  final DateTime? confirmedAt;

  @override
  List<Object?> get props => [
    phase,
    session,
    missing,
    failure?.kind,
    confirmedAt,
  ];
}

/// 23 Submit result: success is shown only after the server's 200.
class SubmitCubit extends Cubit<SubmitState> {
  SubmitCubit(
    this._repo,
    this.sessionId, {
    this.events,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const SubmitState());

  final CollectionRepository _repo;
  final String sessionId;
  final CollectionEvents? events;
  final DateTime Function() _now;

  Future<void> submit() async {
    emit(const SubmitState());
    try {
      final s = await _repo.completeSession(sessionId);
      events?.changed(sessionId);
      if (!isClosed) {
        emit(
          SubmitState(
            phase: SubmitPhase.success,
            session: s,
            confirmedAt: _now(),
          ),
        );
      }
    } on IncompleteSession catch (e) {
      if (!isClosed) {
        emit(SubmitState(phase: SubmitPhase.missing, missing: e.missing));
      }
    } on Failure catch (f) {
      if (!isClosed) emit(SubmitState(phase: SubmitPhase.failed, failure: f));
    }
  }
}
