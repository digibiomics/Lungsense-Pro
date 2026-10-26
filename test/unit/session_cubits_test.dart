import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/session_outcome.dart';
import 'package:lungsense_pro/features/authentication/domain/repositories/auth_repository.dart';
import 'package:lungsense_pro/features/authentication/domain/usecases/session_usecases.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/login_cubit.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/session_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late StreamController<void> expired;

  SessionCubit sessionCubit() => SessionCubit(
    restoreSession: RestoreSession(repo),
    signOut: SignOut(repo),
    repository: repo,
  );

  setUp(() {
    repo = MockAuthRepository();
    expired = StreamController<void>.broadcast();
    when(() => repo.sessionExpired).thenAnswer((_) => expired.stream);
    when(() => repo.signOut()).thenAnswer((_) async {});
  });

  tearDown(() => expired.close());

  group('SessionCubit', () {
    blocTest<SessionCubit, SessionState>(
      'restore resolves to the backend outcome',
      setUp: () =>
          when(() => repo.restoreSession())
              .thenAnswer((_) async => userWith(role: UserRole.patient)),
      build: sessionCubit,
      act: (c) => c.restore(),
      expect: () => [
        const SessionChecking(),
        SessionResolved(Authenticated(userWith(role: UserRole.patient))),
      ],
    );

    blocTest<SessionCubit, SessionState>(
      'offline restore reports failure so the user can retry',
      setUp: () =>
          when(() => repo.restoreSession())
              .thenThrow(const Failure(kind: FailureKind.network)),
      build: sessionCubit,
      act: (c) => c.restore(),
      expect: () => [
        const SessionChecking(),
        const SessionRestoreFailed(Failure(kind: FailureKind.network)),
      ],
    );

    blocTest<SessionCubit, SessionState>(
      'session expiry while signed in returns to signed out',
      build: sessionCubit,
      seed: () => const SessionResolved(Authenticated(testUser)),
      act: (c) async {
        expired.add(null);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [const SessionResolved(SignedOut())],
    );

    blocTest<SessionCubit, SessionState>(
      'expiry during restore is ignored (restore reports its own outcome)',
      build: sessionCubit,
      act: (c) async {
        expired.add(null);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => <SessionState>[],
    );

    blocTest<SessionCubit, SessionState>(
      'signOut clears storage',
      build: sessionCubit,
      seed: () => const SessionResolved(Authenticated(testUser)),
      act: (c) => c.signOut(),
      expect: () => [const SessionResolved(SignedOut())],
      verify: (_) => verify(() => repo.signOut()).called(1),
    );
  });

  group('LoginCubit', () {
    late SessionCubit session;
    setUp(() => session = sessionCubit());
    tearDown(() => session.close());

    LoginCubit loginCubit() => LoginCubit(
      signIn: SignInWithEmail(repo),
      resendConfirmation: ResendConfirmation(repo),
      session: session,
    );

    test('success hands the outcome to the session', () async {
      when(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testUser);
      final c = loginCubit();
      await c.submit(email: 'a@b.co', password: 'pw');
      expect(c.state, const LoginState());
      expect(session.state, const SessionResolved(Authenticated(testUser)));
      await c.close();
    });

    test('duplicate submissions are ignored while one is running', () async {
      final gate = Completer<AppUser>();
      when(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => gate.future);
      final c = loginCubit();
      final first = c.submit(email: 'a@b.co', password: 'pw');
      await c.submit(email: 'a@b.co', password: 'pw');
      expect(c.state.submitting, isTrue);
      gate.complete(testUser);
      await first;
      verify(
        () => repo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(1);
      await c.close();
    });

    blocTest<LoginCubit, LoginState>(
      'resend confirmation reports sent',
      setUp: () =>
          when(() => repo.resendConfirmation(any())).thenAnswer((_) async {}),
      build: loginCubit,
      seed: () => const LoginState(error: LoginError.emailNotConfirmed),
      act: (c) => c.resendConfirmation('a@b.co'),
      expect: () => const [
        LoginState(
          error: LoginError.emailNotConfirmed,
          resend: ResendStatus.sending,
        ),
        LoginState(
          error: LoginError.emailNotConfirmed,
          resend: ResendStatus.sent,
        ),
      ],
    );
  });

  group('mapLoginFailure', () {
    Failure f(FailureKind k, {String? msg, String? code}) =>
        Failure(kind: k, message: msg, code: code);

    test('400 variants', () {
      expect(
        mapLoginFailure(
          f(FailureKind.badRequest, msg: 'Invalid login credentials'),
        ),
        LoginError.wrongCredentials,
      );
      expect(
        mapLoginFailure(f(FailureKind.badRequest, msg: 'Email not confirmed')),
        LoginError.emailNotConfirmed,
      );
      expect(
        mapLoginFailure(f(FailureKind.badRequest, code: 'email_not_confirmed')),
        LoginError.emailNotConfirmed,
      );
    });

    test('other statuses', () {
      expect(
        mapLoginFailure(f(FailureKind.rateLimited)),
        LoginError.tooManyAttempts,
      );
      expect(
        mapLoginFailure(f(FailureKind.serviceUnavailable)),
        LoginError.serviceUnavailable,
      );
      expect(mapLoginFailure(f(FailureKind.timeout)), LoginError.network);
      expect(mapLoginFailure(f(FailureKind.server)), LoginError.unexpected);
    });
  });
}
