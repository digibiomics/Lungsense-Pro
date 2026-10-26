import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/session_outcome.dart';
import 'package:lungsense_pro/features/authentication/domain/repositories/auth_repository.dart';
import 'package:lungsense_pro/features/authentication/domain/usecases/session_usecases.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.signOut()).thenAnswer((_) async {});
  });

  group('SignInWithEmail', () {
    test(
      'trims email and returns Authenticated for an active doctor',
      () async {
        when(() => repo.signIn(email: 'dr.rao@example.com', password: 'pw'))
            .thenAnswer((_) async => testUser);
        final out = await SignInWithEmail(repo)(
          email: '  dr.rao@example.com ',
          password: 'pw',
        );
        expect(out, const Authenticated(testUser));
        verifyNever(() => repo.signOut());
      },
    );

    test('pending doctor profile signs out again', () async {
      when(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => userWith(status: AccountStatus.pendingApproval),
      );
      final out = await SignInWithEmail(repo)(email: 'a@b.co', password: 'pw');
      expect(out, const AccountRestricted(AccountStatus.pendingApproval));
      verify(() => repo.signOut()).called(1);
    });

    test('403 account code becomes a restriction with the message', () async {
      when(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const Failure(
          kind: FailureKind.forbidden,
          statusCode: 403,
          code: 'account_rejected',
          message: 'Credentials could not be verified.',
        ),
      );
      final out = await SignInWithEmail(repo)(email: 'a@b.co', password: 'pw');
      expect(
        out,
        const AccountRestricted(
          AccountStatus.rejected,
          message: 'Credentials could not be verified.',
        ),
      );
    });

    test('other 403 codes are rethrown, not shown as approval', () async {
      when(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const Failure(kind: FailureKind.forbidden, code: 'wrong_role'),
      );
      expect(
        () => SignInWithEmail(repo)(email: 'a@b.co', password: 'pw'),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('RestoreSession', () {
    test('no stored session -> SignedOut', () async {
      when(() => repo.restoreSession()).thenAnswer((_) async => null);
      expect(await RestoreSession(repo)(), const SignedOut());
    });

    test('active admin -> Authenticated', () async {
      final admin = userWith(role: UserRole.admin);
      when(() => repo.restoreSession()).thenAnswer((_) async => admin);
      expect(await RestoreSession(repo)(), Authenticated(admin));
    });

    test('401 clears and signs out', () async {
      when(() => repo.restoreSession()).thenThrow(
        const Failure(kind: FailureKind.unauthorized, statusCode: 401),
      );
      expect(await RestoreSession(repo)(), const SignedOut());
      verify(() => repo.signOut()).called(1);
    });

    test('403 suspended -> restricted', () async {
      when(() => repo.restoreSession()).thenThrow(
        const Failure(kind: FailureKind.forbidden, code: 'account_suspended'),
      );
      expect(
        await RestoreSession(repo)(),
        const AccountRestricted(AccountStatus.suspended),
      );
    });

    test('network failure is rethrown and the session kept', () async {
      when(() => repo.restoreSession())
          .thenThrow(const Failure(kind: FailureKind.network));
      expect(() => RestoreSession(repo)(), throwsA(isA<Failure>()));
      verifyNever(() => repo.signOut());
    });
  });
}
