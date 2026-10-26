import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/usecases/session_usecases.dart';
import 'session_cubit.dart';

/// Login error variants from the design (Login.dc.html) and API docs.
enum LoginError {
  wrongCredentials,
  emailNotConfirmed,
  tooManyAttempts,
  serviceUnavailable,
  network,
  unexpected,
}

enum ResendStatus { idle, sending, sent, failed }

class LoginState extends Equatable {
  const LoginState({
    this.submitting = false,
    this.error,
    this.serverMessage,
    this.resend = ResendStatus.idle,
  });

  final bool submitting;
  final LoginError? error;

  /// Server message for [LoginError.unexpected] only (never stack traces).
  final String? serverMessage;
  final ResendStatus resend;

  LoginState copyWith({
    bool? submitting,
    LoginError? Function()? error,
    String? Function()? serverMessage,
    ResendStatus? resend,
  }) => LoginState(
    submitting: submitting ?? this.submitting,
    error: error != null ? error() : this.error,
    serverMessage: serverMessage != null ? serverMessage() : this.serverMessage,
    resend: resend ?? this.resend,
  );

  @override
  List<Object?> get props => [submitting, error, serverMessage, resend];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required this._signIn,
    required ResendConfirmation resendConfirmation,
    required this._session,
  }) : _resend = resendConfirmation,
       super(const LoginState());

  final SignInWithEmail _signIn;
  final ResendConfirmation _resend;
  final SessionCubit _session;

  Future<void> submit({required String email, required String password}) async {
    if (state.submitting) return; // duplicate-submission guard
    emit(const LoginState(submitting: true));
    try {
      final outcome = await _signIn(email: email, password: password);
      if (isClosed) return;
      emit(const LoginState());
      _session.resolve(outcome);
    } on Failure catch (f) {
      if (isClosed) return;
      final error = mapLoginFailure(f);
      emit(
        LoginState(
          error: error,
          serverMessage: error == LoginError.unexpected ? f.message : null,
        ),
      );
    }
  }

  Future<void> resendConfirmation(String email) async {
    if (state.resend == ResendStatus.sending) return;
    emit(state.copyWith(resend: ResendStatus.sending));
    try {
      await _resend(email);
      if (!isClosed) emit(state.copyWith(resend: ResendStatus.sent));
    } on Failure {
      if (!isClosed) emit(state.copyWith(resend: ResendStatus.failed));
    }
  }

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(error: () => null, serverMessage: () => null));
    }
  }
}

/// The API documents two 400 cases for login without a distinguishing code,
/// so the unconfirmed-email case is recognised by `detail.code` if present,
/// otherwise by the message text. See docs/KNOWN_ISSUES.md (KI-04).
LoginError mapLoginFailure(Failure f) {
  switch (f.kind) {
    case FailureKind.badRequest:
    case FailureKind.unauthorized:
      final code = f.code?.toLowerCase() ?? '';
      final msg = f.message?.toLowerCase() ?? '';
      final unconfirmed =
          code.contains('confirm') ||
          code.contains('verif') ||
          msg.contains('not confirmed') ||
          msg.contains('confirm your email') ||
          msg.contains('not verified') ||
          msg.contains('verify your email');
      return unconfirmed
          ? LoginError.emailNotConfirmed
          : LoginError.wrongCredentials;
    case FailureKind.rateLimited:
      return LoginError.tooManyAttempts;
    case FailureKind.serviceUnavailable:
      return LoginError.serviceUnavailable;
    case FailureKind.network:
    case FailureKind.timeout:
      return LoginError.network;
    default:
      return LoginError.unexpected;
  }
}
