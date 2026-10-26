import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../domain/entities/doctor_application.dart';
import '../../domain/usecases/admin_usecases.dart';

enum ApplicationTab { pending, approved, rejected }

extension ApplicationTabX on ApplicationTab {
  String get label => switch (this) {
    ApplicationTab.pending => 'Pending',
    ApplicationTab.approved => 'Approved',
    ApplicationTab.rejected => 'Rejected',
  };

  /// Entries without a recognised status are listed as pending review.
  bool matches(DoctorApplication a) => switch (this) {
    ApplicationTab.pending =>
      a.status == AccountStatus.pendingApproval ||
          a.status == AccountStatus.unknown,
    ApplicationTab.approved => a.status == AccountStatus.active,
    ApplicationTab.rejected => a.status == AccountStatus.rejected,
  };
}

class AdminDoctorsState extends Equatable {
  const AdminDoctorsState({
    this.loading = true,
    this.items = const [],
    this.failure,
    this.tab = ApplicationTab.pending,
  });

  final bool loading;
  final List<DoctorApplication> items;
  final Failure? failure;
  final ApplicationTab tab;

  List<DoctorApplication> get visible => items.where(tab.matches).toList();
  int count(ApplicationTab t) => items.where(t.matches).length;

  AdminDoctorsState copyWith({
    bool? loading,
    List<DoctorApplication>? items,
    Failure? Function()? failure,
    ApplicationTab? tab,
  }) => AdminDoctorsState(
    loading: loading ?? this.loading,
    items: items ?? this.items,
    failure: failure != null ? failure() : this.failure,
    tab: tab ?? this.tab,
  );

  @override
  List<Object?> get props => [loading, items, failure?.kind, tab];
}

class AdminDoctorsCubit extends Cubit<AdminDoctorsState> {
  AdminDoctorsCubit(this._list) : super(const AdminDoctorsState());
  final ListDoctorApplications _list;

  Future<void> load() async {
    emit(state.copyWith(loading: true, failure: () => null));
    try {
      final items = await _list();
      if (!isClosed) emit(state.copyWith(loading: false, items: items));
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(loading: false, failure: () => f));
    }
  }

  void selectTab(ApplicationTab t) => emit(state.copyWith(tab: t));

  /// Applies a decision made on the review screen, then re-reads the list.
  Future<void> applyDecision(DoctorApplication updated) async {
    emit(
      state.copyWith(
        items: [
          for (final a in state.items) a.userId == updated.userId ? updated : a,
        ],
      ),
    );
    await load();
  }
}

enum ReviewAction { approve, reject }

class AdminReviewState extends Equatable {
  const AdminReviewState({
    required this.application,
    this.busy,
    this.failure,
    this.decided = false,
  });

  final DoctorApplication application;
  final ReviewAction? busy;
  final Failure? failure;

  /// True once the server confirmed approve/reject (2xx).
  final bool decided;

  @override
  List<Object?> get props => [application, busy, failure?.kind, decided];
}

class AdminReviewCubit extends Cubit<AdminReviewState> {
  AdminReviewCubit({
    required DoctorApplication application,
    required this._approve,
    required this._reject,
  }) : super(AdminReviewState(application: application));

  final ApproveDoctor _approve;
  final RejectDoctor _reject;

  Future<void> approve() async {
    if (state.busy != null || state.decided) return;
    emit(
      AdminReviewState(
        application: state.application,
        busy: ReviewAction.approve,
      ),
    );
    try {
      await _approve(state.application.userId);
      if (isClosed) return;
      emit(
        AdminReviewState(
          application: state.application.withStatus(AccountStatus.active),
          decided: true,
        ),
      );
    } on Failure catch (f) {
      if (!isClosed) {
        emit(AdminReviewState(application: state.application, failure: f));
      }
    }
  }

  Future<void> reject(String reason) async {
    if (state.busy != null || state.decided || reason.trim().isEmpty) return;
    emit(
      AdminReviewState(
        application: state.application,
        busy: ReviewAction.reject,
      ),
    );
    try {
      await _reject(state.application.userId, reason);
      if (isClosed) return;
      emit(
        AdminReviewState(
          application: state.application.withStatus(
            AccountStatus.rejected,
            reason: reason.trim(),
          ),
          decided: true,
        ),
      );
    } on Failure catch (f) {
      if (!isClosed) {
        emit(AdminReviewState(application: state.application, failure: f));
      }
    }
  }
}
