import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';
import 'package:lungsense_pro/features/authentication/domain/repositories/auth_repository.dart';
import 'package:lungsense_pro/features/authentication/domain/usecases/session_usecases.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/login_cubit.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/session_cubit.dart';
import 'package:lungsense_pro/features/authentication/presentation/pages/login_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';

// MOCKED repository: these tests check UI behaviour only.
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late SessionCubit session;

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.sessionExpired).thenAnswer((_) => const Stream.empty());
    when(() => repo.signOut()).thenAnswer((_) async {});
    session = SessionCubit(
      restoreSession: RestoreSession(repo),
      signOut: SignOut(repo),
      repository: repo,
    );
  });

  tearDown(() => session.close());

  Future<void> pump(WidgetTester tester) => pumpPage(
    tester,
    BlocProvider(
      create: (_) => LoginCubit(
        signIn: SignInWithEmail(repo),
        resendConfirmation: ResendConfirmation(repo),
        session: session,
      ),
      child: const LoginPage(),
    ),
    session: session,
  );

  void stubSignIn(Future<AppUser> Function() answer) => when(
    () => repo.signIn(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) => answer());

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'dr.rao@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'Example#123',
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
  }

  testWidgets('empty form shows validation errors and sends nothing', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.byKey(const Key('login_submit')));
    await t.pump();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    verifyNever(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('invalid email is rejected', (t) async {
    await pump(t);
    await t.enterText(find.byKey(const Key('login_email')), 'not-an-email');
    await t.enterText(find.byKey(const Key('login_password')), 'x');
    await t.tap(find.byKey(const Key('login_submit')));
    await t.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('password visibility toggles', (t) async {
    await pump(t);
    EditableText field() => t.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('login_password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field().obscureText, isTrue);
    await t.tap(find.byTooltip('Show password'));
    await t.pump();
    expect(field().obscureText, isFalse);
    await t.tap(find.byTooltip('Hide password'));
    await t.pump();
    expect(field().obscureText, isTrue);
  });

  testWidgets('shows loading state and blocks double taps', (t) async {
    final gate = Completer<AppUser>();
    stubSignIn(() => gate.future);
    await pump(t);
    await fillAndSubmit(t);
    expect(find.text('Signing in…'), findsOneWidget);
    await t.tap(find.byKey(const Key('login_submit')));
    await t.pump();
    verify(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1);
    gate.complete(testUser);
    await t.pumpAndSettle();
  });

  testWidgets('wrong password banner', (t) async {
    stubSignIn(
      () => Future.error(
        const Failure(
          kind: FailureKind.badRequest,
          message: 'Invalid login credentials',
        ),
      ),
    );
    await pump(t);
    await fillAndSubmit(t);
    await t.pumpAndSettle();
    expect(find.textContaining('Wrong email or password.'), findsOneWidget);
  });

  testWidgets('unconfirmed email offers resend and calls the API', (t) async {
    stubSignIn(
      () => Future.error(
        const Failure(
          kind: FailureKind.badRequest,
          message: 'Email not confirmed',
        ),
      ),
    );
    when(() => repo.resendConfirmation(any())).thenAnswer((_) async {});
    await pump(t);
    await fillAndSubmit(t);
    await t.pumpAndSettle();
    expect(find.textContaining('Confirm your email first.'), findsOneWidget);
    await t.tap(find.text('Resend confirmation email'));
    await t.pumpAndSettle();
    verify(() => repo.resendConfirmation('dr.rao@example.com')).called(1);
    expect(find.text('Request received'), findsOneWidget);
  });

  testWidgets('429 shows the rate-limit banner', (t) async {
    stubSignIn(
      () => Future.error(const Failure(kind: FailureKind.rateLimited)),
    );
    await pump(t);
    await fillAndSubmit(t);
    await t.pumpAndSettle();
    expect(find.textContaining('Too many attempts.'), findsOneWidget);
  });

  testWidgets('503 shows the server-side banner', (t) async {
    stubSignIn(
      () => Future.error(const Failure(kind: FailureKind.serviceUnavailable)),
    );
    await pump(t);
    await fillAndSubmit(t);
    await t.pumpAndSettle();
    expect(find.textContaining('Server-side problem.'), findsOneWidget);
  });

  testWidgets('Google sign-in is shown as unavailable', (t) async {
    await pump(t);
    expect(find.text('Google sign-in isn\'t available yet.'), findsOneWidget);
    final button = t.widget<TextButton>(
      find.ancestor(
        of: find.text('Continue with Google'),
        matching: find.byType(TextButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
