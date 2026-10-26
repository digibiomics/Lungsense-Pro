import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../authentication/domain/entities/registration.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/domain/usecases/session_usecases.dart';

class AccountTypeState extends Equatable {
  const AccountTypeState({
    this.accountType,
    this.submitting = false,
    this.failure,
  });

  /// No preselection, as in email sign-up.
  final AccountType? accountType;
  final bool submitting;
  final Failure? failure;

  Map<String, String> get fieldErrors => failure?.fieldErrors ?? const {};

  @override
  List<Object?> get props => [
    accountType,
    submitting,
    failure?.kind,
    failure?.message,
  ];
}

/// Google first-time account-type step (`POST /users/me/account-type`).
/// The outcome is handed to [onOutcome] (the session) only after the server
/// answers; nothing is decided locally.
class AccountTypeCubit extends Cubit<AccountTypeState> {
  AccountTypeCubit(this._complete, {required this.onOutcome})
    : super(const AccountTypeState());

  final CompleteAccountType _complete;
  final void Function(SessionOutcome) onOutcome;

  void chooseType(AccountType t) => emit(AccountTypeState(accountType: t));

  void clearError() {
    if (state.failure != null) {
      emit(AccountTypeState(accountType: state.accountType));
    }
  }

  Future<void> submit({
    required String fullName,
    DoctorProfileInput? doctorProfile,
  }) async {
    final type = state.accountType;
    if (state.submitting || type == null) return;
    if (type == AccountType.doctor && doctorProfile == null) return;
    emit(AccountTypeState(accountType: type, submitting: true));
    try {
      final outcome = await _complete(
        AccountTypeRequest(
          accountType: type,
          fullName: fullName.trim(),
          doctorProfile: type == AccountType.doctor ? doctorProfile : null,
        ),
      );
      if (isClosed) return;
      emit(AccountTypeState(accountType: type));
      onOutcome(outcome);
    } on Failure catch (f) {
      if (!isClosed) emit(AccountTypeState(accountType: type, failure: f));
    }
  }
}
