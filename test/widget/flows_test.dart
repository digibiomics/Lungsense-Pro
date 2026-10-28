import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/app/app.dart';
import 'package:lungsense_pro/app/di.dart';
import 'package:lungsense_pro/features/collection/domain/services/draft_visibility.dart';
import 'package:lungsense_pro/core/network/api_endpoints.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/session_cubit.dart';

import '../helpers/fakes.dart';

// End-to-end UI flows with the real router, DI, cubits, repositories and
// request models. Only HTTP is MOCKED (MockHttpAdapter): these tests prove
// what the app sends and how it reacts, not that the live backend agrees.
void main() {
  late InMemoryTokenStorage storage;
  late MockHttpAdapter http;

  setUp(() {
    storage = InMemoryTokenStorage();
    http = MockHttpAdapter((_) => const MockReply(404));
  });

  Future<void> launch(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await configureDependencies(
      storage: storage,
      dio: mockDio(http),
      hiddenDrafts: MemoryHiddenDraftsStore(),
    );
    final session = sl<SessionCubit>()..restore();
    await t.pumpWidget(LungSenseProApp(session: session));
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> type(WidgetTester t, String key, String text) async {
    final f = find.byKey(Key(key));
    await t.ensureVisible(f);
    await t.enterText(f, text);
  }

  Map<String, dynamic> bodyOf(String path) {
    final r = http.requests.lastWhere((r) => r.path == path);
    final d = r.data;
    return (d is String ? jsonDecode(d) : d) as Map<String, dynamic>;
  }

  Future<void> signIn(WidgetTester t) async {
    await tap(t, find.text('Sign in'));
    await type(t, 'login_email', 'a@example.com');
    await type(t, 'login_password', 'Example#123');
    await tap(t, find.byKey(const Key('login_submit')));
  }

  group('sign-up', () {
    Future<void> fillAccount(WidgetTester t, {required String role}) async {
      await tap(t, find.text('Create an account'));
      expect(
        find.byKey(const Key('role_continue')).hitTestable(),
        findsOneWidget,
      );
      await tap(t, find.byKey(Key('role_$role')));
      await tap(t, find.byKey(const Key('role_continue')));
      await type(t, 'reg_name', 'Asha Patel');
      await type(t, 'reg_email', 'asha@example.com');
      await type(t, 'reg_password', 'Example#123');
      await tap(t, find.byKey(const Key('reg_consent')));
      await tap(t, find.byKey(const Key('reg_continue')));
    }

    testWidgets('patient sends the documented body and lands on Verify', (
      t,
    ) async {
      http.handler = (o) => o.path == ApiEndpoints.register
          ? const MockReply(201, {'id': 'x'})
          : const MockReply(404);
      await launch(t);
      await fillAccount(t, role: 'patient');

      expect(bodyOf(ApiEndpoints.register), {
        'email': 'asha@example.com',
        'password': 'Example#123',
        'full_name': 'Asha Patel',
        'account_type': 'patient',
      });
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.text('asha@example.com'), findsOneWidget);
      expect(storage.refresh, isNull); // registration never signs in
    });

    testWidgets('continue is disabled until a role is chosen', (t) async {
      await launch(t);
      await tap(t, find.text('Create an account'));
      await tap(t, find.byKey(const Key('role_continue')));
      expect(find.byKey(const Key('reg_name')), findsNothing);
    });

    testWidgets('doctor sends doctor_profile with credential_notes', (t) async {
      http.handler = (o) => o.path == ApiEndpoints.register
          ? const MockReply(201, {'id': 'x'})
          : const MockReply(404);
      await launch(t);
      await fillAccount(t, role: 'doctor');
      expect(http.count(ApiEndpoints.register), 0);

      await type(t, 'doc_license_number', 'KMC-1');
      await type(t, 'doc_specialty', 'Pulmonology');
      await type(t, 'doc_institution', 'City Hospital');
      await type(t, 'doc_city', 'Srinagar');
      await type(t, 'doc_country', 'India');
      await type(t, 'doc_phone', '+91 99999 00000');
      await type(t, 'doc_credential_notes', 'MBBS, MD');
      await tap(t, find.byKey(const Key('doctor_submit')));

      final body = bodyOf(ApiEndpoints.register);
      expect(body['account_type'], 'doctor');
      expect(body['doctor_profile'], {
        'license_number': 'KMC-1',
        'specialty': 'Pulmonology',
        'institution': 'City Hospital',
        'city': 'Srinagar',
        'country': 'India',
        'phone': '+91 99999 00000',
        'credential_notes': 'MBBS, MD',
      });
      expect(find.text('Check your email'), findsOneWidget);
    });

    testWidgets('duplicate email shows sign-in and reset options', (t) async {
      http.handler = (o) => o.path == ApiEndpoints.register
          ? const MockReply(422, {'detail': 'Email already registered'})
          : const MockReply(404);
      await launch(t);
      await fillAccount(t, role: 'patient');
      expect(
        find.textContaining('This email is already registered.'),
        findsOneWidget,
      );
      expect(find.text('Check your email'), findsNothing);
    });
  });

  group('password recovery', () {
    Future<void> openReset(WidgetTester t) async {
      await tap(t, find.text('Sign in'));
      await tap(t, find.text('Forgot password?'));
      await type(t, 'forgot_email', 'p@example.com');
      await tap(t, find.byKey(const Key('forgot_send')));
    }

    testWidgets('forgot password is neutral even when the server says 404', (
      t,
    ) async {
      http.handler = (o) => o.path == ApiEndpoints.forgotPassword
          ? const MockReply(404, {'detail': 'User not found'})
          : const MockReply(404);
      await launch(t);
      await openReset(t);
      expect(bodyOf(ApiEndpoints.forgotPassword), {'email': 'p@example.com'});
      expect(find.textContaining('Check your email.'), findsOneWidget);
      expect(find.textContaining('not found'), findsNothing);
    });

    testWidgets('reset sends three fields; 400 marks the code invalid', (
      t,
    ) async {
      var status = 400;
      http.handler = (o) => switch (o.path) {
        ApiEndpoints.forgotPassword => const MockReply(200, {'message': 'ok'}),
        ApiEndpoints.resetPassword => MockReply(status, {
          'detail': 'Invalid or expired code',
        }),
        _ => const MockReply(404),
      };
      await launch(t);
      await openReset(t);
      await tap(t, find.byKey(const Key('forgot_enter_code')));

      await type(t, 'reset_code', '123456');
      await type(t, 'reset_password', 'NewPass#123');
      await type(t, 'reset_confirm', 'Different#1');
      await tap(t, find.byKey(const Key('reset_submit')));
      expect(find.text('The passwords don\'t match.'), findsOneWidget);
      expect(http.count(ApiEndpoints.resetPassword), 0);

      await type(t, 'reset_confirm', 'NewPass#123');
      await tap(t, find.byKey(const Key('reset_submit')));
      expect(bodyOf(ApiEndpoints.resetPassword), {
        'email': 'p@example.com',
        'otp_code': '123456',
        'new_password': 'NewPass#123',
      });
      expect(find.text('This code is invalid or has expired.'), findsOneWidget);

      status = 200;
      await type(t, 'reset_code', '654321');
      await tap(t, find.byKey(const Key('reset_submit')));
      expect(find.textContaining('Password updated.'), findsOneWidget);
      await tap(t, find.text('Go to sign in'));
      expect(find.byKey(const Key('login_submit')), findsOneWidget);
    });
  });

  group('roles', () {
    testWidgets('admin approves a pending doctor from the list', (t) async {
      final approved = <String>[];
      http.handler = (o) {
        if (o.path == ApiEndpoints.login) return MockReply(200, tokenJson());
        if (o.path == ApiEndpoints.me) {
          return MockReply(200, meJson(role: 'admin'));
        }
        if (o.path == ApiEndpoints.adminDoctors) {
          return MockReply(200, [
            {
              'id': 'd-7',
              'email': 'dr.khan@example.com',
              'full_name': 'Dr. S. Khan',
              'account_status': approved.isEmpty
                  ? 'pending_approval'
                  : 'active',
              'doctor_profile': {'license_number': 'KMC-7'},
            },
          ]);
        }
        if (o.path == ApiEndpoints.approveDoctor('d-7')) {
          approved.add('d-7');
          return const MockReply(200, {'status': 'approved'});
        }
        return const MockReply(404);
      };
      await launch(t);
      await signIn(t);
      expect(find.text('Doctor approvals'), findsOneWidget);

      await tap(t, find.text('Dr. S. Khan'));
      expect(find.text('KMC-7'), findsOneWidget);
      await tap(t, find.byKey(const Key('review_approve')));

      expect(approved, ['d-7']);
      expect(find.textContaining('Approved.'), findsOneWidget);
      final approveReq = http.requests.lastWhere(
        (r) => r.path == ApiEndpoints.approveDoctor('d-7'),
      );
      expect(approveReq.method, 'POST');
    });

    testWidgets('admin reject sends the reason', (t) async {
      http.handler = (o) {
        if (o.path == ApiEndpoints.login) return MockReply(200, tokenJson());
        if (o.path == ApiEndpoints.me) {
          return MockReply(200, meJson(role: 'admin'));
        }
        if (o.path == ApiEndpoints.adminDoctors) {
          return const MockReply(200, {
            'items': [
              {
                'user_id': 'd-8',
                'email': 'dr.lone@example.com',
                'full_name': 'Dr. R. Lone',
                'account_status': 'pending_approval',
              },
            ],
          });
        }
        if (o.path == ApiEndpoints.rejectDoctor('d-8')) {
          return const MockReply(200, {'status': 'rejected'});
        }
        return const MockReply(404);
      };
      await launch(t);
      await signIn(t);
      await tap(t, find.text('Dr. R. Lone'));
      await tap(t, find.byKey(const Key('review_reject')));
      await t.enterText(
        find.byKey(const Key('reject_reason')),
        'Licence not found',
      );
      await tap(t, find.byKey(const Key('reject_confirm')));
      expect(bodyOf(ApiEndpoints.rejectDoctor('d-8')), {
        'reason': 'Licence not found',
      });
      expect(find.textContaining('Rejected.'), findsOneWidget);
    });

    testWidgets('admin list failure is shown, never an empty success', (
      t,
    ) async {
      http.handler = (o) => switch (o.path) {
        ApiEndpoints.login => MockReply(200, tokenJson()),
        ApiEndpoints.me => MockReply(200, meJson(role: 'admin')),
        ApiEndpoints.adminDoctors => const MockReply(200, {'weird': true}),
        _ => const MockReply(404),
      };
      await launch(t);
      await signIn(t);
      expect(
        find.textContaining('Couldn\'t load applications.'),
        findsOneWidget,
      );
    });

    testWidgets('new Google-style user picks a role via account-type', (
      t,
    ) async {
      var role = 'new';
      http.handler = (o) => switch (o.path) {
        ApiEndpoints.login => MockReply(200, tokenJson()),
        ApiEndpoints.me => MockReply(200, meJson(role: role)),
        ApiEndpoints.meAccountType => () {
          role = 'patient';
          return MockReply(200, meJson(role: 'patient'));
        }(),
        _ => const MockReply(404),
      };
      await launch(t);
      await signIn(t);
      expect(find.text('Who is this account for?'), findsOneWidget);

      await tap(t, find.byKey(const Key('role_patient')));
      await type(t, 'select_name', 'Asha Patel');
      await tap(t, find.byKey(const Key('select_continue')));

      expect(bodyOf(ApiEndpoints.meAccountType), {
        'account_type': 'patient',
        'full_name': 'Asha Patel',
      });
      expect(find.text('Today\'s check-in'), findsOneWidget);
    });

    testWidgets('signed-in user can open Change password from Profile', (
      t,
    ) async {
      http.handler = (o) => switch (o.path) {
        ApiEndpoints.login => MockReply(200, tokenJson()),
        ApiEndpoints.me => MockReply(200, meJson(role: 'patient')),
        _ => const MockReply(404),
      };
      await launch(t);
      await signIn(t);
      await tap(t, find.text('Profile'));
      await tap(t, find.byKey(const Key('profile_change_password')));
      expect(find.text('Reset your password'), findsOneWidget);
      final field = t.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('forgot_email')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field.controller.text, 'dr.rao@example.com');
    });
  });
}
