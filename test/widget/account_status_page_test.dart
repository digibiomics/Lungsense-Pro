import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/features/account_status/presentation/pages/account_status_page.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/session_outcome.dart';
import 'package:lungsense_pro/features/authentication/domain/repositories/auth_repository.dart';
import 'package:lungsense_pro/features/authentication/domain/usecases/session_usecases.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/session_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SessionCubit session;

  setUp(() {
    final repo = MockAuthRepository();
    when(() => repo.sessionExpired).thenAnswer((_) => const Stream.empty());
    session = SessionCubit(
      restoreSession: RestoreSession(repo),
      signOut: SignOut(repo),
      repository: repo,
    );
  });

  tearDown(() => session.close());

  Future<void> show(WidgetTester t, AccountRestricted r) async {
    session.resolve(r);
    await pumpPage(t, const AccountStatusPage(), session: session);
  }

  testWidgets('pending approval', (t) async {
    await show(t, const AccountRestricted(AccountStatus.pendingApproval));
    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.textContaining('You stay signed out'), findsOneWidget);
  });

  testWidgets('rejected shows the server reason', (t) async {
    await show(
      t,
      const AccountRestricted(
        AccountStatus.rejected,
        message: 'Professional credentials could not be verified.',
      ),
    );
    expect(find.text('Account not approved'), findsOneWidget);
    expect(
      find.textContaining('Professional credentials could not be verified.'),
      findsOneWidget,
    );
  });

  testWidgets('suspended and deactivated', (t) async {
    await show(t, const AccountRestricted(AccountStatus.suspended));
    expect(find.text('Account not active'), findsOneWidget);
    expect(find.text('Suspended'), findsOneWidget);

    session.resolve(const AccountRestricted(AccountStatus.deactivated));
    await t.pumpAndSettle();
    expect(find.text('Deactivated'), findsOneWidget);
  });

  testWidgets('Close returns to signed out', (t) async {
    await show(t, const AccountRestricted(AccountStatus.rejected));
    await t.tap(find.text('Close'));
    await t.pump();
    expect(session.state, const SessionResolved(SignedOut()));
  });
}
