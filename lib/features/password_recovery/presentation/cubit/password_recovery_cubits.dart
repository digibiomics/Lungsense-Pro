import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../authentication/domain/usecases/session_usecases.dart';

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.sending = false,
    this.sent = false,
    this.failure,
  });

  final bool sending;

  /// Neutral "if an account exists" state. Shown for every server answer
  /// except connectivity / rate-limit / outage, so registered emails are
  /// never revealed.
  final bool sent;
  final Failure? failure;

  @override
  List<Object?> get props => [sending, sent, failure?.kind];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._request) : super(const ForgotPasswordState());
  final RequestPasswordReset _request;

  Future<void> submit(String email) async {
    if (state.sending) return;
    emit(const ForgotPasswordState(sending: true));
    try {
      await _request(email);
      if (!isClosed) emit(const ForgotPasswordState(sent: true));
    } on Failure catch (f) {
      if (isClosed) return;
      final transient =
          f.isConnectivity ||
          f.kind == FailureKind.rateLimited ||
          f.kind == FailureKind.serviceUnavailable ||
          f.kind == FailureKind.server;
      emit(
        transient
            ? ForgotPasswordState(failure: f)
            : const ForgotPasswordState(sent: true),
      );
    }
  }
}

enum ResetError { invalidCode, rejected, other }

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.submitting = false,
    this.done = false,
    this.error,
    this.failure,
  });

  final bool submitting;
  final bool done;
  final ResetError? error;
  final Failure? failure;

  Map<String, String> get fieldErrors => failure?.fieldErrors ?? const {};

  @override
  List<Object?> get props => [
    submitting,
    done,
    error,
    failure?.kind,
    failure?.message,
    fieldErrors,
  ];
}

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit(this._reset) : super(const ResetPasswordState());
  final ResetPassword _reset;

  Future<void> submit({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    if (state.submitting || state.done) return;
    emit(const ResetPasswordState(submitting: true));
    try {
      await _reset(email: email, otpCode: otpCode, newPassword: newPassword);
      if (!isClosed) emit(const ResetPasswordState(done: true));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(ResetPasswordState(error: mapResetFailure(f), failure: f));
    }
  }

  void clearError() {
    if (state.error != null) emit(const ResetPasswordState());
  }
}

/// 400 = invalid or expired code (documented). 422 = validation (e.g.
/// password rules), shown under the field when the server names it.
ResetError mapResetFailure(Failure f) => switch (f.kind) {
  FailureKind.badRequest => ResetError.invalidCode,
  FailureKind.validation => ResetError.rejected,
  _ => ResetError.other,
};
