import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/services/device_services.dart';
import 'collection_events.dart';

class CollectionSessionState extends Equatable {
  const CollectionSessionState({this.session, this.failure});

  /// Null until the first load succeeds.
  final CollectionSession? session;
  final Failure? failure;

  bool get loading => session == null && failure == null;

  @override
  List<Object?> get props => [session, failure?.kind];
}

/// Reads one session from the server (Overview, Review, Session detail).
/// Every step saves to the server itself, so screens reload instead of
/// sharing local state.
class CollectionSessionCubit extends Cubit<CollectionSessionState> {
  CollectionSessionCubit(
    this._repo,
    this.sessionId, {
    CollectionEvents? events,
    this._opener,
  }) : super(const CollectionSessionState()) {
    _sub = events?.changes.listen((id) {
      if (id == sessionId) load();
    });
  }

  final CollectionRepository _repo;
  final String sessionId;
  final LinkOpener? _opener;
  StreamSubscription<String>? _sub;

  /// Opens a short-lived download link for an X-ray. False when it failed.
  Future<bool> openXray(String xrayId) async {
    final opener = _opener;
    if (opener == null) return false;
    try {
      return await opener.open(await _repo.xrayDownloadUrl(xrayId));
    } on Failure {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  Future<void> load() async {
    if (state.failure != null) {
      emit(CollectionSessionState(session: state.session));
    }
    try {
      final s = await _repo.getSession(sessionId);
      if (!isClosed) emit(CollectionSessionState(session: s));
    } on Failure catch (f) {
      if (!isClosed) {
        emit(CollectionSessionState(session: state.session, failure: f));
      }
    }
  }
}
