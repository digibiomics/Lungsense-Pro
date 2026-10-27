import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/usecases/admin_usecases.dart';

class AdminUsersState extends Equatable {
  const AdminUsersState({
    this.loading = true,
    this.loadingMore = false,
    this.items = const [],
    this.total = 0,
    this.query = '',
    this.failure,
    this.busyUserId,
    this.actionFailure,
    this.lastChanged,
  });

  final bool loading;
  final bool loadingMore;
  final List<AdminUser> items;
  final int total;
  final String query;

  /// Loading the list failed.
  final Failure? failure;

  /// User whose status change is waiting for the server.
  final String? busyUserId;

  /// The last status change failed.
  final Failure? actionFailure;

  /// The account the server just confirmed a change for (drives the toast).
  final AdminUser? lastChanged;

  bool get hasMore => items.length < total;

  AdminUsersState copyWith({
    bool? loading,
    bool? loadingMore,
    List<AdminUser>? items,
    int? total,
    String? query,
    Failure? Function()? failure,
    String? Function()? busyUserId,
    Failure? Function()? actionFailure,
    AdminUser? Function()? lastChanged,
  }) => AdminUsersState(
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    items: items ?? this.items,
    total: total ?? this.total,
    query: query ?? this.query,
    failure: failure != null ? failure() : this.failure,
    busyUserId: busyUserId != null ? busyUserId() : this.busyUserId,
    actionFailure: actionFailure != null ? actionFailure() : this.actionFailure,
    lastChanged: lastChanged != null ? lastChanged() : this.lastChanged,
  );

  @override
  List<Object?> get props => [
    loading,
    loadingMore,
    items,
    total,
    query,
    failure?.kind,
    busyUserId,
    actionFailure,
    lastChanged,
  ];
}

/// 29 Admin · users: search, suspend and reactivate.
class AdminUsersCubit extends Cubit<AdminUsersState> {
  AdminUsersCubit(this._list, this._setStatus) : super(const AdminUsersState());

  final ListUsers _list;
  final SetUserStatus _setStatus;
  int _generation = 0;

  Future<void> load() => _fetch(state.query);

  Future<void> search(String query) {
    if (query.trim() == state.query.trim() && !state.loading) {
      return Future.value();
    }
    return _fetch(query);
  }

  Future<void> _fetch(String query) async {
    final gen = ++_generation;
    emit(
      state.copyWith(
        loading: true,
        query: query,
        failure: () => null,
        actionFailure: () => null,
      ),
    );
    try {
      final page = await _list(search: query);
      if (isClosed || gen != _generation) return;
      emit(
        state.copyWith(loading: false, items: page.items, total: page.total),
      );
    } on Failure catch (f) {
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(loading: false, items: [], failure: () => f));
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
    } on Failure catch (f) {
      if (!isClosed) {
        emit(state.copyWith(loadingMore: false, actionFailure: () => f));
      }
    }
  }

  /// Applies the change only after the server returns the updated account.
  Future<void> changeStatus(
    AdminUser user,
    UserStatusChange status, {
    String? reason,
  }) async {
    if (state.busyUserId != null) return;
    emit(
      state.copyWith(
        busyUserId: () => user.id,
        actionFailure: () => null,
        lastChanged: () => null,
      ),
    );
    try {
      final updated = await _setStatus(user.id, status, reason: reason);
      if (isClosed) return;
      emit(
        state.copyWith(
          busyUserId: () => null,
          items: [
            for (final u in state.items) u.id == updated.id ? updated : u,
          ],
          lastChanged: () => updated,
        ),
      );
    } on Failure catch (f) {
      if (!isClosed) {
        emit(state.copyWith(busyUserId: () => null, actionFailure: () => f));
      }
    }
  }
}
