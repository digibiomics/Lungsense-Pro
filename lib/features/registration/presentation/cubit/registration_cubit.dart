import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../authentication/domain/entities/registration.dart';
import '../../../authentication/domain/usecases/session_usecases.dart';

enum RegistrationStatus { editing, submitting, succeeded, failed }

class RegistrationState extends Equatable {
  const RegistrationState({
    this.accountType,
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.consent = false,
    this.status = RegistrationStatus.editing,
    this.failure,
    this.duplicate = false,
  });

  /// No preselection: the role can't be changed later, so it is an explicit
  /// choice.
  final AccountType? accountType;
  final String fullName;
  final String email;
  final String password;
  final bool consent;
  final RegistrationStatus status;
  final Failure? failure;

  /// 422/409 "already registered".
  final bool duplicate;

  bool get isDoctor => accountType == AccountType.doctor;
  int get totalSteps => isDoctor ? 3 : 2;
  bool get submitting => status == RegistrationStatus.submitting;

  /// Field-level server messages keyed by request field name.
  Map<String, String> get fieldErrors => failure?.fieldErrors ?? const {};

  RegistrationState copyWith({
    AccountType? accountType,
    String? fullName,
    String? email,
    String? password,
    bool? consent,
    RegistrationStatus? status,
    Failure? Function()? failure,
    bool? duplicate,
  }) => RegistrationState(
    accountType: accountType ?? this.accountType,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    password: password ?? this.password,
    consent: consent ?? this.consent,
    status: status ?? this.status,
    failure: failure != null ? failure() : this.failure,
    duplicate: duplicate ?? this.duplicate,
  );

  @override
  List<Object?> get props => [
    accountType,
    fullName,
    email,
    password,
    consent,
    status,
    failure?.kind,
    failure?.message,
    fieldErrors,
    duplicate,
  ];
}

/// Holds the multi-step sign-up (RoleChoice → Register → RegisterDoctor) and
/// submits `POST /auth/register` once.
class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit(this._register) : super(const RegistrationState());

  final RegisterAccount _register;

  void chooseType(AccountType type) =>
      emit(state.copyWith(accountType: type, failure: () => null));

  void setConsent(bool value) => emit(state.copyWith(consent: value));

  void saveAccount({
    required String fullName,
    required String email,
    required String password,
  }) => emit(
    state.copyWith(
      fullName: fullName.trim(),
      email: email.trim(),
      password: password,
    ),
  );

  void clearError() {
    if (state.failure != null || state.duplicate) {
      emit(
        state.copyWith(
          status: RegistrationStatus.editing,
          failure: () => null,
          duplicate: false,
        ),
      );
    }
  }

  Future<void> submit({DoctorProfileInput? doctorProfile}) async {
    final type = state.accountType;
    if (state.submitting || type == null || !state.consent) return;
    if (type == AccountType.doctor && doctorProfile == null) return;

    emit(
      state.copyWith(
        status: RegistrationStatus.submitting,
        failure: () => null,
        duplicate: false,
      ),
    );
    try {
      await _register(
        RegistrationRequest(
          email: state.email,
          password: state.password,
          fullName: state.fullName,
          accountType: type,
          doctorProfile: type == AccountType.doctor ? doctorProfile : null,
        ),
      );
      if (!isClosed) emit(state.copyWith(status: RegistrationStatus.succeeded));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RegistrationStatus.failed,
          failure: () => f,
          duplicate: FailureMessages.isDuplicateAccount(f),
        ),
      );
    }
  }
}
