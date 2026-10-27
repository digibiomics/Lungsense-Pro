import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../collection/domain/entities/collection_session.dart';
import '../../../collection/domain/repositories/collection_repository.dart';
import '../../../collection/presentation/cubit/collection_events.dart';
import '../../domain/entities/patient.dart';
import '../../domain/usecases/patient_usecases.dart';

// -------------------------------------------------------------- Patient list

class PatientsState extends Equatable {
  const PatientsState({
    this.loading = true,
    this.loadingMore = false,
    this.items = const [],
    this.total = 0,
    this.query = '',
    this.failure,
  });

  final bool loading;
  final bool loadingMore;
  final List<PatientSummary> items;
  final int total;
  final String query;
  final Failure? failure;

  bool get hasMore => items.length < total;

  PatientsState copyWith({
    bool? loading,
    bool? loadingMore,
    List<PatientSummary>? items,
    int? total,
    String? query,
    Failure? Function()? failure,
  }) => PatientsState(
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    items: items ?? this.items,
    total: total ?? this.total,
    query: query ?? this.query,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    loadingMore,
    items,
    total,
    query,
    failure?.kind,
  ];
}

/// 11 Patient list and 16 Start collection's patient picker: server-side
/// search by study ID / reference, most recent first.
class PatientsCubit extends Cubit<PatientsState> {
  PatientsCubit(this._list, {CollectionEvents? events})
    : super(const PatientsState()) {
    // A new session changes "last session" and session counts.
    _sub = events?.changes.listen((_) => load());
  }

  final ListPatients _list;
  StreamSubscription<String>? _sub;
  int _generation = 0;

  Future<void> load() => _fetch(state.query);

  Future<void> search(String q) =>
      q.trim() == state.query.trim() && !state.loading
      ? Future.value()
      : _fetch(q);

  Future<void> _fetch(String q) async {
    final gen = ++_generation;
    emit(state.copyWith(loading: true, query: q, failure: () => null));
    try {
      final page = await _list(search: q);
      if (isClosed || gen != _generation) return;
      emit(
        state.copyWith(loading: false, items: page.items, total: page.total),
      );
    } on Failure catch (f) {
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(loading: false, failure: () => f));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final gen = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _list(search: state.query, offset: state.items.length);
      if (isClosed || gen != _generation) return;
      emit(
        state.copyWith(
          loadingMore: false,
          items: [...state.items, ...page.items],
          total: page.total,
        ),
      );
    } on Failure {
      if (!isClosed) emit(state.copyWith(loadingMore: false));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

// --------------------------------------------------------- Add / edit form

enum PatientFormPhase { editing, saving, duplicate, saved }

class PatientFormState extends Equatable {
  const PatientFormState({
    this.phase = PatientFormPhase.editing,
    this.initial,
    this.loadingInitial = false,
    this.loadFailure,
    this.failure,
    this.duplicate,
    this.saved,
  });

  final PatientFormPhase phase;

  /// The record being edited (null when adding).
  final Patient? initial;
  final bool loadingInitial;
  final Failure? loadFailure;
  final Failure? failure;
  final PossibleDuplicate? duplicate;
  final Patient? saved;

  Map<String, String> get fieldErrors => failure?.fieldErrors ?? const {};

  @override
  List<Object?> get props => [
    phase,
    initial,
    loadingInitial,
    loadFailure?.kind,
    failure?.kind,
    failure?.message,
    duplicate?.matches,
    saved,
  ];
}

/// 12 Add patient (AddPatient.dc.html) and Edit from Patient detail.
class PatientFormCubit extends Cubit<PatientFormState> {
  PatientFormCubit(this._save, this._get, {this.patientId})
    : super(PatientFormState(loadingInitial: patientId != null));

  final SavePatient _save;
  final GetPatient _get;

  /// Set when editing.
  final String? patientId;

  bool get editing => patientId != null;

  Future<void> loadInitial() async {
    if (patientId == null) return;
    emit(const PatientFormState(loadingInitial: true));
    try {
      final p = await _get(patientId!);
      if (!isClosed) emit(PatientFormState(initial: p));
    } on Failure catch (f) {
      if (!isClosed) emit(PatientFormState(loadFailure: f));
    }
  }

  /// [allowDuplicate] resends after a `409 possible_duplicate`.
  Future<void> submit(PatientInput input, {bool allowDuplicate = false}) async {
    if (state.phase == PatientFormPhase.saving) return;
    emit(
      PatientFormState(phase: PatientFormPhase.saving, initial: state.initial),
    );
    try {
      final p = await _save(
        input,
        id: patientId,
        allowDuplicate: allowDuplicate,
      );
      if (!isClosed) {
        emit(
          PatientFormState(
            phase: PatientFormPhase.saved,
            initial: state.initial,
            saved: p,
          ),
        );
      }
    } on PossibleDuplicate catch (d) {
      if (!isClosed) {
        emit(
          PatientFormState(
            phase: PatientFormPhase.duplicate,
            initial: state.initial,
            duplicate: d,
          ),
        );
      }
    } on Failure catch (f) {
      if (!isClosed) {
        emit(PatientFormState(initial: state.initial, failure: f));
      }
    }
  }
}

// ----------------------------------------------------------- Patient detail

class PatientDetailState extends Equatable {
  const PatientDetailState({
    this.patient,
    this.sessions = const [],
    this.totalSessions = 0,
    this.failure,
    this.sessionsFailure,
  });

  final Patient? patient;
  final List<SessionSummary> sessions;
  final int totalSessions;
  final Failure? failure;
  final Failure? sessionsFailure;

  bool get loading => patient == null && failure == null;

  @override
  List<Object?> get props => [
    patient,
    sessions,
    totalSessions,
    failure?.kind,
    sessionsFailure?.kind,
  ];
}

/// 13 Patient detail: the record and its collection sessions.
class PatientDetailCubit extends Cubit<PatientDetailState> {
  PatientDetailCubit(
    this._get,
    this._collection,
    this.patientId, {
    CollectionEvents? events,
  }) : super(const PatientDetailState()) {
    _sub = events?.changes.listen((_) => load());
  }

  final GetPatient _get;
  final CollectionRepository _collection;
  final String patientId;
  StreamSubscription<String>? _sub;

  Future<void> load() async {
    // The record decides the screen; a failed session list shows inline.
    final sessions = _sessions();
    try {
      final p = await _get(patientId);
      final s = await sessions;
      if (isClosed) return;
      emit(
        PatientDetailState(
          patient: p,
          sessions: s.items,
          totalSessions: s.total,
          sessionsFailure: s.failure,
        ),
      );
    } on Failure catch (f) {
      if (!isClosed) {
        emit(PatientDetailState(patient: state.patient, failure: f));
      }
    }
  }

  Future<({List<SessionSummary> items, int total, Failure? failure})>
  _sessions() async {
    try {
      final page = await _collection.listSessions(patientId: patientId);
      return (items: page.items, total: page.total, failure: null);
    } on Failure catch (f) {
      return (items: const <SessionSummary>[], total: 0, failure: f);
    }
  }

  void applyUpdate(Patient p) => emit(
    PatientDetailState(
      patient: p,
      sessions: state.sessions,
      totalSessions: state.totalSessions,
      sessionsFailure: state.sessionsFailure,
    ),
  );

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
