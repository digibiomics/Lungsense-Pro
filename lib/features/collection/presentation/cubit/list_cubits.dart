import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/services/draft_visibility.dart';
import 'collection_events.dart';

// ----------------------------------------------------------- Start session

class StartSessionState extends Equatable {
  const StartSessionState({this.starting = false, this.failure, this.created});

  final bool starting;
  final Failure? failure;

  /// The session the server created (navigate to its overview).
  final CollectionSession? created;

  @override
  List<Object?> get props => [starting, failure?.kind, created?.id];
}

/// `POST /collection/sessions` for 16 Start collection and the patient
/// check-in.
class StartSessionCubit extends Cubit<StartSessionState> {
  StartSessionCubit(this._repo, {this.events})
    : super(const StartSessionState());

  final CollectionRepository _repo;
  final CollectionEvents? events;

  /// Doctors pass the patient; patients pass nothing.
  Future<CollectionSession?> start({String? patientId}) async {
    if (state.starting) return null;
    emit(const StartSessionState(starting: true));
    try {
      final s = await _repo.createSession(patientId: patientId);
      events?.changed(s.id);
      if (!isClosed) emit(StartSessionState(created: s));
      return s;
    } on Failure catch (f) {
      if (!isClosed) emit(StartSessionState(failure: f));
      return null;
    }
  }

  /// Clears an earlier failure once its cause is fixed.
  void reset() {
    if (!state.starting) emit(const StartSessionState());
  }
}

// ------------------------------------------------------------ Session list

enum SessionFilter { all, drafts, completed }

class SessionsState extends Equatable {
  const SessionsState({
    this.loading = true,
    this.loadingMore = false,
    this.items = const [],
    this.total = 0,
    this.fetched = 0,
    this.filter = SessionFilter.all,
    this.failure,
  });

  final bool loading;
  final bool loadingMore;
  final List<SessionSummary> items;
  final int total;

  /// Rows read from the server, including hidden drafts (the next offset).
  final int fetched;
  final SessionFilter filter;
  final Failure? failure;

  bool get hasMore => fetched < total;

  SessionsState copyWith({
    bool? loading,
    bool? loadingMore,
    List<SessionSummary>? items,
    int? total,
    int? fetched,
    SessionFilter? filter,
    Failure? Function()? failure,
  }) => SessionsState(
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    items: items ?? this.items,
    total: total ?? this.total,
    fetched: fetched ?? this.fetched,
    filter: filter ?? this.filter,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    loading,
    loadingMore,
    items,
    total,
    fetched,
    filter,
    failure?.kind,
  ];
}

/// 14 Collection history (doctor) and 26 My check-ins (patient).
class SessionsCubit extends Cubit<SessionsState> {
  SessionsCubit(this._repo, {CollectionEvents? events, this._drafts})
    : super(const SessionsState()) {
    _sub = events?.changes.listen((_) => load());
  }

  final CollectionRepository _repo;
  final DraftVisibility? _drafts;
  StreamSubscription<String>? _sub;
  int _generation = 0;

  /// Pages read in a row while every row is a hidden draft.
  static const _maxSkippedPages = 5;

  /// Reads from [offset] until a page has a visible row or nothing is left.
  Future<({List<SessionSummary> items, int total, int fetched})> _page(
    SessionFilter f,
    int offset,
  ) async {
    final items = <SessionSummary>[];
    var fetched = offset;
    var total = 0;
    for (var i = 0; i < _maxSkippedPages; i++) {
      final page = await _repo.listSessions(
        status: _status(f),
        offset: fetched,
      );
      total = page.total;
      fetched += page.items.length;
      items.addAll(await _drafts?.visible(page.items) ?? page.items);
      if (items.isNotEmpty || page.items.isEmpty || fetched >= total) break;
    }
    return (items: items, total: total, fetched: fetched);
  }

  static SessionStatus? _status(SessionFilter f) => switch (f) {
    SessionFilter.all => null,
    SessionFilter.drafts => SessionStatus.draft,
    SessionFilter.completed => SessionStatus.completed,
  };

  Future<void> load() => _fetch(state.filter);

  Future<void> setFilter(SessionFilter f) =>
      f == state.filter ? Future.value() : _fetch(f);

  Future<void> _fetch(SessionFilter f) async {
    final gen = ++_generation;
    emit(state.copyWith(loading: true, filter: f, failure: () => null));
    try {
      final page = await _page(f, 0);
      if (isClosed || gen != _generation) return;
      emit(
        state.copyWith(
          loading: false,
          items: page.items,
          total: page.total,
          fetched: page.fetched,
        ),
      );
    } on Failure catch (e) {
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(loading: false, failure: () => e));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final gen = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _page(state.filter, state.fetched);
      if (isClosed || gen != _generation) return;
      emit(
        state.copyWith(
          loadingMore: false,
          items: [...state.items, ...page.items],
          total: page.total,
          fetched: page.fetched,
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

// --------------------------------------------------------------- Dashboard

class DashboardState extends Equatable {
  const DashboardState({this.stats, this.drafts = const [], this.failure});

  final DashboardStats? stats;

  /// Newest drafts ("Drafts to finish").
  final List<SessionSummary> drafts;
  final Failure? failure;

  bool get loading => stats == null && failure == null;

  @override
  List<Object?> get props => [stats, drafts, failure?.kind];
}

/// 10 Doctor dashboard: counts and recent activity from
/// `GET /collection/dashboard`, drafts from `GET /collection/sessions`.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repo, {CollectionEvents? events, this._drafts})
    : super(const DashboardState()) {
    _sub = events?.changes.listen((_) => load());
  }

  final CollectionRepository _repo;
  final DraftVisibility? _drafts;
  StreamSubscription<String>? _sub;

  static const draftsShown = 3;

  /// Drafts read so enough remain after hiding removed and expired ones.
  static const _draftsRead = 20;

  Future<void> load() async {
    if (state.failure != null) emit(DashboardState(stats: state.stats));
    try {
      final drafts = _repo.listSessions(
        status: SessionStatus.draft,
        limit: _drafts == null ? draftsShown : _draftsRead,
      );
      final stats = await _repo.dashboard();
      final d = await drafts;
      final shown = await _drafts?.visible(d.items) ?? d.items;
      if (!isClosed) {
        emit(
          DashboardState(
            stats: stats,
            drafts: shown.take(draftsShown).toList(),
          ),
        );
      }
    } on Failure catch (f) {
      if (!isClosed) {
        emit(
          DashboardState(stats: state.stats, drafts: state.drafts, failure: f),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

// ------------------------------------------------------------ Patient home

class PatientHomeState extends Equatable {
  const PatientHomeState({
    this.loading = true,
    this.recent = const [],
    this.failure,
  });

  final bool loading;
  final List<SessionSummary> recent;
  final Failure? failure;

  /// Today's unfinished check-in, if any (resume it instead of starting
  /// another).
  SessionSummary? todaysDraft(DateTime now) => _today(now, draft: true);

  /// Today's submitted check-in, if any.
  SessionSummary? todaysCompleted(DateTime now) => _today(now, draft: false);

  SessionSummary? _today(DateTime now, {required bool draft}) {
    for (final s in recent) {
      final t = s.startedAt?.toLocal();
      final n = now.toLocal();
      if (t != null &&
          t.year == n.year &&
          t.month == n.month &&
          t.day == n.day &&
          (draft ? s.isDraft : s.isCompleted)) {
        return s;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [loading, recent, failure?.kind];
}

/// 25 Patient home: today's check-in state and recent check-ins.
class PatientHomeCubit extends Cubit<PatientHomeState> {
  PatientHomeCubit(this._repo, {CollectionEvents? events, this._drafts})
    : super(const PatientHomeState()) {
    _sub = events?.changes.listen((_) => load());
  }

  final CollectionRepository _repo;
  final DraftVisibility? _drafts;
  StreamSubscription<String>? _sub;

  static const shown = 5;

  Future<void> load() async {
    emit(PatientHomeState(loading: true, recent: state.recent));
    try {
      final page = await _repo.listSessions(limit: shown);
      final recent = await _drafts?.visible(page.items) ?? page.items;
      if (!isClosed) emit(PatientHomeState(loading: false, recent: recent));
    } on Failure catch (f) {
      if (!isClosed) {
        emit(
          PatientHomeState(loading: false, recent: state.recent, failure: f),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
