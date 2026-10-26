import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../authentication/domain/usecases/session_usecases.dart';

class ResendState extends Equatable {
  const ResendState({
    this.sending = false,
    this.sent = false,
    this.cooldown = 0,
    this.failure,
  });

  final bool sending;

  /// The server accepted the request (202). Not proof of delivery.
  final bool sent;

  /// Seconds before another resend is allowed.
  final int cooldown;
  final Failure? failure;

  @override
  List<Object?> get props => [sending, sent, cooldown, failure?.kind];
}

/// `POST /auth/resend-confirmation` with a 60 s client cooldown
/// (VerifyEmail.dc.html "Resend available in 60 s").
class ResendConfirmationCubit extends Cubit<ResendState> {
  ResendConfirmationCubit(this._resend, {this.cooldownSeconds = 60})
    : super(const ResendState());

  final ResendConfirmation _resend;
  final int cooldownSeconds;
  Timer? _timer;

  Future<void> resend(String email) async {
    if (state.sending || state.cooldown > 0) return;
    emit(const ResendState(sending: true));
    try {
      await _resend(email);
      if (isClosed) return;
      emit(ResendState(sent: true, cooldown: cooldownSeconds));
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        final left = state.cooldown - 1;
        if (left <= 0) t.cancel();
        if (!isClosed) {
          emit(ResendState(sent: true, cooldown: left < 0 ? 0 : left));
        }
      });
    } on Failure catch (f) {
      if (!isClosed) emit(ResendState(failure: f));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
