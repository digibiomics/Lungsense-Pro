import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/features/admin/domain/entities/doctor_application.dart';
import 'package:lungsense_pro/features/admin/domain/repositories/admin_repository.dart';
import 'package:lungsense_pro/features/admin/domain/usecases/admin_usecases.dart';
import 'package:lungsense_pro/features/admin/presentation/cubit/admin_cubits.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/registration.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/session_outcome.dart';
import 'package:lungsense_pro/features/authentication/domain/repositories/auth_repository.dart';
import 'package:lungsense_pro/features/authentication/domain/usecases/session_usecases.dart';
import 'package:lungsense_pro/features/password_recovery/presentation/cubit/password_recovery_cubits.dart';
import 'package:lungsense_pro/features/registration/presentation/cubit/account_type_cubit.dart';
import 'package:lungsense_pro/features/registration/presentation/cubit/registration_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

// MOCKED repositories: cubit behaviour only.
class MockAuthRepository extends Mock implements AuthRepository {}

class MockAdminRepository extends Mock implements AdminRepository {}

const _app = DoctorApplication(
  userId: 'd-1',
  email: 'dr@example.com',
  status: AccountStatus.pendingApproval,
);

void main() {
  late MockAuthRepository auth;
  late MockAdminRepository admin;

  setUpAll(() {
    registerFallbackValue(
      const RegistrationRequest(
        email: '',
        password: '',
        fullName: '',
        accountType: AccountType.patient,
      ),
    );
    registerFallbackValue(
      const AccountTypeRequest(accountType: AccountType.patient, fullName: ''),
    );
  });

  setUp(() {
    auth = MockAuthRepository();
    admin = MockAdminRepository();
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  group('ForgotPasswordCubit', () {
    for (final kind in [FailureKind.notFound, FailureKind.validation]) {
      blocTest<ForgotPasswordCubit, ForgotPasswordState>(
        '$kind still shows the neutral result',
        build: () {
          when(() => auth.requestPasswordReset(any()))
              .thenThrow(Failure(kind: kind, message: 'No such user'));
          return ForgotPasswordCubit(RequestPasswordReset(auth));
        },
        act: (c) => c.submit('x@example.com'),
        expect: () => [
          const ForgotPasswordState(sending: true),
          const ForgotPasswordState(sent: true),
        ],
      );
    }

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'connectivity failure is reported so the user can retry',
      build: () {
        when(() => auth.requestPasswordReset(any()))
            .thenThrow(const Failure(kind: FailureKind.network));
        return ForgotPasswordCubit(RequestPasswordReset(auth));
      },
      act: (c) => c.submit('x@example.com'),
      expect: () => [
        const ForgotPasswordState(sending: true),
        const ForgotPasswordState(failure: Failure(kind: FailureKind.network)),
      ],
    );
  });

  test('reset failures map 400 to invalid code and 422 to rejected', () {
    expect(
      mapResetFailure(const Failure(kind: FailureKind.badRequest)),
      ResetError.invalidCode,
    );
    expect(
      mapResetFailure(const Failure(kind: FailureKind.validation)),
      ResetError.rejected,
    );
    expect(
      mapResetFailure(const Failure(kind: FailureKind.server)),
      ResetError.other,
    );
  });

  group('RegistrationCubit', () {
    test('needs a role and consent before submitting', () async {
      final c = RegistrationCubit(RegisterAccount(auth));
      await c.submit();
      c.chooseType(AccountType.patient);
      await c.submit();
      verifyNever(() => auth.register(any()));
      await c.close();
    });

    test('a doctor without a profile is not submitted', () async {
      final c = RegistrationCubit(RegisterAccount(auth))
        ..chooseType(AccountType.doctor)
        ..setConsent(true);
      await c.submit();
      verifyNever(() => auth.register(any()));
      await c.close();
    });
  });

  group('AdminReviewCubit', () {
    blocTest<AdminReviewCubit, AdminReviewState>(
      'a failed approve is not shown as decided',
      build: () {
        when(() => admin.approveDoctor('d-1'))
            .thenThrow(const Failure(kind: FailureKind.forbidden));
        return AdminReviewCubit(
          application: _app,
          approve: ApproveDoctor(admin),
          reject: RejectDoctor(admin),
        );
      },
      act: (c) => c.approve(),
      verify: (c) {
        expect(c.state.decided, isFalse);
        expect(c.state.failure?.kind, FailureKind.forbidden);
        expect(c.state.application.status, AccountStatus.pendingApproval);
      },
    );

    blocTest<AdminReviewCubit, AdminReviewState>(
      'reject passes the reason and marks the application rejected',
      build: () {
        when(() => admin.rejectDoctor('d-1', reason: 'No licence'))
            .thenAnswer((_) async {});
        return AdminReviewCubit(
          application: _app,
          approve: ApproveDoctor(admin),
          reject: RejectDoctor(admin),
        );
      },
      act: (c) => c.reject('No licence'),
      verify: (c) {
        expect(c.state.decided, isTrue);
        expect(c.state.application.status, AccountStatus.rejected);
      },
    );
  });

  test('pending tab includes entries with an unrecognised status', () {
    expect(ApplicationTab.pending.matches(_app), isTrue);
    expect(
      ApplicationTab.pending.matches(_app.withStatus(AccountStatus.unknown)),
      isTrue,
    );
    expect(ApplicationTab.approved.matches(_app), isFalse);
  });

  group('AccountTypeCubit', () {
    test('hands a pending doctor outcome to the session', () async {
      when(() => auth.setAccountType(any())).thenAnswer(
        (_) async => userWith(status: AccountStatus.pendingApproval),
      );
      final outcomes = <SessionOutcome>[];
      final c = AccountTypeCubit(
        CompleteAccountType(auth),
        onOutcome: outcomes.add,
      )..chooseType(AccountType.doctor);
      await c.submit(
        fullName: 'Dr. D',
        doctorProfile: const DoctorProfileInput(
          licenseNumber: 'L',
          specialty: 'S',
          institution: 'I',
          city: 'C',
          country: 'IN',
          phone: '1',
        ),
      );
      expect(outcomes.single, isA<AccountRestricted>());
      verify(() => auth.signOut()).called(1);
      await c.close();
    });

    test('a server failure stays on the screen', () async {
      when(
        () => auth.setAccountType(any()),
      ).thenThrow(const Failure(kind: FailureKind.validation, message: 'Bad'));
      final outcomes = <SessionOutcome>[];
      final c = AccountTypeCubit(
        CompleteAccountType(auth),
        onOutcome: outcomes.add,
      )..chooseType(AccountType.patient);
      await c.submit(fullName: 'P');
      expect(outcomes, isEmpty);
      expect(c.state.failure?.message, 'Bad');
      await c.close();
    });
  });
}
