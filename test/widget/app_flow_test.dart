import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/app/app.dart';
import 'package:lungsense_pro/app/di.dart';
import 'package:lungsense_pro/core/network/api_endpoints.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/session_cubit.dart';

import '../helpers/fakes.dart';

// Full app with the real router, cubits, repository and interceptor.
// Only the HTTP layer is MOCKED (MockHttpAdapter) and storage is in-memory.
void main() {
  late InMemoryTokenStorage storage;
  late MockHttpAdapter http;

  setUp(() {
    storage = InMemoryTokenStorage();
    http = MockHttpAdapter((_) => const MockReply(404));
  });

  Future<void> launch(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await configureDependencies(storage: storage, dio: mockDio(http));
    final session = sl<SessionCubit>()..restore();
    await t.pumpWidget(LungSenseProApp(session: session));
    await t.pumpAndSettle();
  }

  testWidgets('no stored session opens Welcome without network calls', (
    t,
  ) async {
    await launch(t);
    expect(find.text('Create an account'), findsOneWidget);
    expect(http.requests, isEmpty);
  });

  testWidgets('stored session for an approved doctor opens the dashboard', (
    t,
  ) async {
    storage.refresh = 'r';
    http.handler = (o) => switch (o.path) {
      ApiEndpoints.refresh => MockReply(200, tokenJson()),
      ApiEndpoints.me => MockReply(200, meJson()),
      _ => const MockReply(404),
    };
    await launch(t);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
  });

  testWidgets('invalid stored session is cleared and returns to Welcome', (
    t,
  ) async {
    storage
      ..access = 'a'
      ..refresh = 'r';
    http.handler = (_) => const MockReply(401, {'detail': 'Invalid token'});
    await launch(t);
    expect(find.text('Create an account'), findsOneWidget);
    expect(storage.refresh, isNull);
  });

  testWidgets('login as pending doctor shows approval screen, logged out', (
    t,
  ) async {
    http.handler = (o) => switch (o.path) {
      ApiEndpoints.login => const MockReply(403, {
        'detail': {
          'code': 'account_pending_approval',
          'message': 'Your account is waiting for approval',
        },
      }),
      _ => const MockReply(404),
    };
    await launch(t);
    await t.tap(find.text('Sign in'));
    await t.pumpAndSettle();
    await t.enterText(
      find.byKey(const Key('login_email')),
      'dr.rao@example.com',
    );
    await t.enterText(find.byKey(const Key('login_password')), 'Example#123');
    await t.tap(find.byKey(const Key('login_submit')));
    await t.pumpAndSettle();
    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(storage.refresh, isNull);
  });

  testWidgets('patient login routes to Patient Home; sign out returns', (
    t,
  ) async {
    http.handler = (o) => switch (o.path) {
      ApiEndpoints.login => MockReply(200, tokenJson()),
      ApiEndpoints.me => MockReply(200, meJson(role: 'patient')),
      _ => const MockReply(404),
    };
    await launch(t);
    await t.tap(find.text('Sign in'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('login_email')), 'p@example.com');
    await t.enterText(find.byKey(const Key('login_password')), 'Example#123');
    await t.tap(find.byKey(const Key('login_submit')));
    await t.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);

    await t.tap(find.byKey(const Key('sign_out')));
    await t.pumpAndSettle();
    expect(find.text('Create an account'), findsOneWidget);
    expect(storage.refresh, isNull);
  });
}
