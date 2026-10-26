import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/session_outcome.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/session_usecases.dart';

sealed class SessionState extends Equatable {
  const SessionState();
  @override
  List<Object?> get props => [];
}

/// Launch: the stored session has not been validated yet.
class SessionChecking extends SessionState {
  const SessionChecking();
}

/// Restore failed for a reason other than an invalid session (offline,
/// timeout, 5xx). Tokens are kept; the splash screen offers a retry.
class SessionRestoreFailed extends SessionState {
  const SessionRestoreFailed(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure.kind, failure.statusCode];
}

/// Settled: one of the domain outcomes.
class SessionResolved extends SessionState {
  const SessionResolved(this.outcome);
  final SessionOutcome outcome;
  @override
  List<Object?> get props => [outcome];
}

/// App-wide session state. The router redirects from this alone.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required RestoreSession restoreSession,
    required this._signOut,
    required AuthRepository repository,
  }) : _restore = restoreSession,
       super(const SessionChecking()) {
    _expiredSub = repository.sessionExpired.listen((_) => _onExpired());
  }

  final RestoreSession _restore;
  final SignOut _signOut;
  late final StreamSubscription<void> _expiredSub;

  Future<void> restore() async {
    emit(const SessionChecking());
    try {
      emit(SessionResolved(await _restore()));
    } on Failure catch (f) {
      emit(SessionRestoreFailed(f));
    }
  }

  /// Called by sign-in flows once the backend has decided the outcome.
  void resolve(SessionOutcome outcome) => emit(SessionResolved(outcome));

  Future<void> signOut() async {
    await _signOut();
    emit(const SessionResolved(SignedOut()));
  }

  /// Leaves an account-status screen (the session is already cleared).
  void dismissRestriction() => emit(const SessionResolved(SignedOut()));

  void _onExpired() {
    final s = state;
    // Only an active session can expire; during restore or sign-in the
    // caller reports the outcome itself.
    if (s is SessionResolved &&
        (s.outcome is Authenticated || s.outcome is RoleSelectionRequired)) {
      emit(const SessionResolved(SignedOut()));
    }
  }

  @override
  Future<void> close() async {
    await _expiredSub.cancel();
    return super.close();
  }
}
