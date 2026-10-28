import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/app/app.dart';
import 'package:lungsense_pro/app/di.dart';
import 'package:lungsense_pro/features/collection/domain/services/draft_visibility.dart';
import 'package:lungsense_pro/core/network/api_endpoints.dart';
import 'package:lungsense_pro/core/widgets/ls_bottom_nav.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/session_cubit.dart';
import 'package:lungsense_pro/features/collection/domain/entities/recording.dart';

import '../helpers/collection_fakes.dart';
import '../helpers/fakes.dart';

// End-to-end UI flows for patients, collection, sessions and admin users,
// with the real router, DI, cubits and repositories. Only HTTP and device
// services are MOCKED.
void main() {
  late InMemoryTokenStorage storage;
  late MockHttpAdapter http;
  late FakeFilePicking files;
  late FakeAudioInspector inspector;

  setUp(() {
    inspector = FakeAudioInspector();
    storage = InMemoryTokenStorage()..refresh = 'r';
    http = MockHttpAdapter((_) => const MockReply(404));
    files = FakeFilePicking();
  });

  Future<void> launch(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await configureDependencies(
      storage: storage,
      dio: mockDio(http),
      devices: fakeDevices(files: files, inspector: inspector),
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

  Finder nav(String label) =>
      find.descendant(of: find.byType(LsBottomNav), matching: find.text(label));

  Map<String, dynamic> bodyOf(String path, {String? method}) {
    final r = http.requests.lastWhere(
      (r) => r.path == path && (method == null || r.method == method),
    );
    final d = r.data;
    return (d is String ? jsonDecode(d) : d) as Map<String, dynamic>;
  }

  MockReply? auth(dynamic o, {String role = 'doctor'}) => switch (o.path) {
    ApiEndpoints.refresh => MockReply(200, tokenJson()),
    ApiEndpoints.me => MockReply(200, meJson(role: role)),
    _ => null,
  };

  group('admin users', () {
    testWidgets('suspend with a reason, then reactivate', (t) async {
      var status = 'active';
      http.handler = (o) {
        final a = auth(o, role: 'admin');
        if (a != null) return a;
        if (o.path == ApiEndpoints.adminDoctors) {
          return MockReply(200, pageJson([]));
        }
        Map<String, dynamic> user() => {
          'id': 'u-3',
          'email': 'o.lone@example.com',
          'full_name': 'Dr. Omar Lone',
          'role': 'doctor',
          'account_status': status,
          'created_at': null,
        };
        if (o.path == ApiEndpoints.adminUsers) {
          return MockReply(200, pageJson([user()]));
        }
        if (o.path == ApiEndpoints.userStatus('u-3')) {
          final b = o.data is String ? jsonDecode(o.data) : o.data;
          status = b['account_status'] as String;
          return MockReply(200, user());
        }
        return const MockReply(404);
      };
      await launch(t);
      await tap(t, find.text('Users'));
      expect(find.text('Dr. Omar Lone'), findsOneWidget);

      await tap(t, find.byKey(const Key('user_action_u-3')));
      await t.enterText(find.byKey(const Key('confirm_reason')), 'Left');
      await tap(t, find.byKey(const Key('suspend_confirm')));
      expect(bodyOf(ApiEndpoints.userStatus('u-3')), {
        'account_status': 'suspended',
        'reason': 'Left',
      });
      expect(find.text('Suspended'), findsOneWidget);
      expect(find.text('Reactivate'), findsOneWidget);

      await t.pump(const Duration(seconds: 5)); // let the toast go
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('user_action_u-3')));
      await tap(t, find.byKey(const Key('reactivate_confirm')));
      expect(bodyOf(ApiEndpoints.userStatus('u-3')), {
        'account_status': 'active',
      });
      expect(find.text('Suspend'), findsOneWidget);
    });

    testWidgets('a failed change keeps the old status', (t) async {
      http.handler = (o) {
        final a = auth(o, role: 'admin');
        if (a != null) return a;
        if (o.path == ApiEndpoints.adminDoctors) {
          return MockReply(200, pageJson([]));
        }
        if (o.path == ApiEndpoints.adminUsers) {
          return MockReply(
            200,
            pageJson([
              {
                'id': 'u-3',
                'email': 'o@example.com',
                'full_name': 'Dr. O',
                'role': 'doctor',
                'account_status': 'active',
                'created_at': null,
              },
            ]),
          );
        }
        return const MockReply(500);
      };
      await launch(t);
      await tap(t, find.text('Users'));
      await tap(t, find.byKey(const Key('user_action_u-3')));
      await tap(t, find.byKey(const Key('suspend_confirm')));
      expect(find.textContaining('Status not changed.'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });
  });

  group('patients', () {
    testWidgets('add patient: duplicate warning, then save anyway', (t) async {
      http.handler = (o) {
        final a = auth(o);
        if (a != null) return a;
        if (o.path == ApiEndpoints.dashboard) {
          return MockReply(200, dashboardJson());
        }
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([]));
        }
        if (o.path == ApiEndpoints.patients && o.method == 'GET') {
          return MockReply(200, pageJson([]));
        }
        if (o.path == ApiEndpoints.patients && o.method == 'POST') {
          final b = o.data is String ? jsonDecode(o.data) : o.data;
          if (b['allow_duplicate'] == true) {
            return MockReply(201, patientJson(id: 'p-2', studyId: 'LS-0143'));
          }
          return const MockReply(409, {
            'detail': {
              'code': 'possible_duplicate',
              'message': 'Possible duplicate',
              'matches': [
                {'id': 'p-119', 'study_id': 'LS-0119'},
              ],
            },
          });
        }
        return const MockReply(404);
      };
      await launch(t);
      await tap(t, find.text('Patients'));
      await tap(t, find.byKey(const Key('patients_add')));

      // Required fields are checked before anything is sent.
      await tap(t, find.byKey(const Key('patient_save')));
      expect(find.text('Choose the patient\'s sex.'), findsOneWidget);
      expect(http.count(ApiEndpoints.patients), 1); // the list GET only

      await t.enterText(find.byKey(const Key('patient_ref')), 'HSP-22871');
      await t.enterText(find.byKey(const Key('patient_age')), '54');
      await tap(t, find.byKey(const Key('patient_sex_male')));
      await tap(t, find.byKey(const Key('patient_consent')));
      await tap(t, find.byKey(const Key('patient_save')));
      expect(bodyOf(ApiEndpoints.patients, method: 'POST'), {
        'external_id': 'HSP-22871',
        'age_years': 54,
        'sex': 'male',
        'consent_status': 'given',
        'relevant_history': null,
        'allow_duplicate': false,
      });
      expect(find.textContaining('LS-0119'), findsOneWidget);

      await tap(t, find.byKey(const Key('patient_save_anyway')));
      expect(
        bodyOf(ApiEndpoints.patients, method: 'POST')['allow_duplicate'],
        true,
      );
      expect(find.byKey(const Key('patient_save')), findsNothing);
    });
  });

  group('collection', () {
    /// A tiny in-memory server for one draft session.
    void serveSession(
      Map<String, dynamic> Function() session, {
      void Function(dynamic o)? onWrite,
      MockReply Function()? complete,
    }) {
      http.handler = (o) {
        final a = auth(o);
        if (a != null) return a;
        if (o.path == ApiEndpoints.dashboard) {
          return MockReply(200, dashboardJson(patients: 1, sessions: 1));
        }
        if (o.path == ApiEndpoints.patients) {
          return MockReply(200, pageJson([patientItemJson()]));
        }
        if (o.path == ApiEndpoints.sessions && o.method == 'POST') {
          onWrite?.call(o);
          return MockReply(201, session());
        }
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([]));
        }
        if (o.path == ApiEndpoints.session('s-1')) {
          onWrite?.call(o);
          return MockReply(200, session());
        }
        if (o.path == ApiEndpoints.sessionSymptoms('s-1')) {
          onWrite?.call(o);
          return MockReply(200, o.method == 'GET' ? null : symptomsJson(1));
        }
        if (o.path == ApiEndpoints.completeSession('s-1')) {
          return complete?.call() ??
              MockReply(200, {...session(), 'status': 'completed'});
        }
        return const MockReply(404);
      };
    }

    testWidgets('start, rate symptoms, add notes, review and submit', (
      t,
    ) async {
      var symptoms = false;
      String? notes;
      serveSession(
        () => sessionJson(
          audio: [
            audioJson(),
            audioJson(id: 'a-2', type: 'breathing'),
          ],
          symptoms: symptoms ? symptomsJson(1) : null,
          notes: notes,
        ),
        onWrite: (o) {
          if (o.method == 'PUT') symptoms = true;
          if (o.method == 'PATCH') {
            notes = (o.data is String ? jsonDecode(o.data) : o.data)['notes'];
          }
        },
      );
      await launch(t);
      expect(find.text('1'), findsWidgets); // dashboard counts

      await tap(t, find.byKey(const Key('dashboard_start')));
      expect(find.text('Select a patient to start'), findsOneWidget);
      await tap(t, find.byKey(const Key('patient_p-1')));
      await tap(t, find.byKey(const Key('start_session')));
      expect(bodyOf(ApiEndpoints.sessions, method: 'POST'), {
        'patient_id': 'p-1',
      });
      expect(find.text('Collection steps'), findsOneWidget);
      expect(find.text('2 of 3 required done'), findsOneWidget);

      await tap(t, find.byKey(const Key('overview_continue')));
      expect(find.text('Symptoms today'), findsOneWidget);
      expect(find.text('0 of 10'), findsOneWidget);
      await tap(t, find.byKey(const Key('symptoms_continue')));
      expect(find.textContaining('Rate 10 more'), findsOneWidget);
      expect(
        http.requests.where((r) => r.method == 'PUT'),
        isEmpty,
        reason: 'nothing is saved until every symptom is rated',
      );
      for (final k in const [
        'breathlessness',
        'activity_limitation',
        'change_from_usual',
        'fever',
        'chest_tightness',
        'chest_discomfort_breathing',
        'wheezing',
        'cough_severity',
        'mucus',
        'sleep_disruption',
      ]) {
        await tap(t, find.byKey(Key('rate_${k}_1')));
        if (k == 'breathlessness') {
          // The chosen level's descriptor appears under the scale.
          expect(find.textContaining('Slight shortness'), findsOneWidget);
        }
      }
      await tap(t, find.byKey(const Key('symptoms_continue')));
      final saved = bodyOf(ApiEndpoints.sessionSymptoms('s-1'), method: 'PUT');
      expect(saved.length, 10);
      expect(saved.values.toSet(), {1});

      expect(find.text('Clinical context'), findsWidgets);
      await t.enterText(find.byKey(const Key('clinical_notes')), 'Night cough');
      await tap(t, find.byKey(const Key('clinical_save')));
      expect(bodyOf(ApiEndpoints.session('s-1'), method: 'PATCH'), {
        'notes': 'Night cough',
      });

      expect(find.text('Review session'), findsWidgets);
      await tap(t, find.byKey(const Key('review_submit')));
      await tap(t, find.byKey(const Key('review_confirm')));
      expect(find.byKey(const Key('submit_success')), findsOneWidget);
      expect(find.textContaining('The server confirmed receipt'), findsOne);
    });

    testWidgets('submit lists what the server says is missing', (t) async {
      serveSession(
        () => sessionJson(
          audio: [
            audioJson(),
            audioJson(id: 'a-2', type: 'breathing'),
          ],
          symptoms: symptomsJson(),
          missing: const [],
        ),
        complete: () => const MockReply(409, {
          'detail': {
            'code': 'incomplete_session',
            'missing': ['symptoms'],
          },
        }),
      );
      await launch(t);
      await tap(t, find.byKey(const Key('dashboard_start')));
      await tap(t, find.byKey(const Key('patient_p-1')));
      await tap(t, find.byKey(const Key('start_session')));
      await tap(t, find.byKey(const Key('overview_review')));
      await tap(t, find.byKey(const Key('review_submit')));
      await tap(t, find.byKey(const Key('review_confirm')));
      expect(find.text('Not submitted yet'), findsOneWidget);
      expect(find.text('Symptoms'), findsOneWidget);
      expect(find.byKey(const Key('submit_success')), findsNothing);
    });

    testWidgets('Submit stays disabled while required items are missing', (
      t,
    ) async {
      serveSession(() => sessionJson());
      await launch(t);
      await tap(t, find.byKey(const Key('dashboard_start')));
      await tap(t, find.byKey(const Key('patient_p-1')));
      await tap(t, find.byKey(const Key('start_session')));
      await tap(t, find.byKey(const Key('overview_review')));
      expect(find.textContaining('3 required items missing.'), findsOneWidget);
      await tap(t, find.byKey(const Key('review_submit')));
      expect(find.byKey(const Key('review_confirm')), findsNothing);
    });

    testWidgets('recorder refuses a 41 s cough file and a short take', (
      t,
    ) async {
      files.audio = const LocalFile(
        path: 'long.m4a',
        name: 'long.m4a',
        sizeBytes: 10,
        contentType: 'audio/mp4',
      );
      inspector.duration = const Duration(seconds: 41);
      serveSession(() => sessionJson());
      await launch(t);
      await tap(t, find.byKey(const Key('dashboard_start')));
      await tap(t, find.byKey(const Key('patient_p-1')));
      await tap(t, find.byKey(const Key('start_session')));
      await tap(t, find.byKey(const Key('step_cough')));
      expect(find.text('Cough recording'), findsOneWidget);
      expect(find.text('Record at least 12 seconds to continue.'), findsOne);

      await tap(t, find.byKey(const Key('rec_import')));
      expect(find.textContaining('This file is 41 s long.'), findsOneWidget);
      expect(
        http.requests.where((r) => r.path.contains('upload-url')),
        isEmpty,
      );

      await t.ensureVisible(find.byKey(const Key('rec_button')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('rec_button')));
      await t.pump();
      await t.pump(const Duration(seconds: 5));
      expect(find.text('Recording'), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('rec_button')));
      await t.pump();
      await t.tap(find.byKey(const Key('rec_button')));
      await t.pumpAndSettle();
      expect(find.text('Too short'), findsOneWidget);
      await t.scrollUntilVisible(
        find.textContaining('Recording too short'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final cont = t.widget<TextButton>(
        find.descendant(
          of: find.byKey(const Key('rec_continue')),
          matching: find.byType(TextButton),
        ),
      );
      expect(cont.onPressed, isNull);
    });
  });

  group('history', () {
    testWidgets('sessions tab filters, opens a read-only completed session', (
      t,
    ) async {
      final done = sessionJson(
        id: 's-9',
        status: 'completed',
        audio: [
          audioJson(),
          audioJson(id: 'a-2', type: 'breathing'),
        ],
        symptoms: symptomsJson(2),
        notes: 'Night cough',
      );
      http.handler = (o) {
        final a = auth(o);
        if (a != null) return a;
        if (o.path == ApiEndpoints.dashboard) {
          return MockReply(200, dashboardJson(patients: 1, sessions: 2));
        }
        if (o.path == ApiEndpoints.sessions) {
          final status = o.queryParameters['status'];
          return MockReply(
            200,
            pageJson([
              if (status != 'complete') sessionJson(),
              if (status != 'draft') done,
            ]),
          );
        }
        if (o.path == ApiEndpoints.session('s-9')) return MockReply(200, done);
        return const MockReply(404);
      };
      await launch(t);
      await tap(t, nav('Sessions'));
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      await tap(t, find.byKey(const Key('filter_completed')));
      expect(http.requests.last.queryParameters['status'], 'complete');
      expect(find.text('Resume'), findsNothing);
      await tap(t, find.byKey(const Key('session_s-9')));
      expect(find.text('Session details'), findsOneWidget);
      expect(find.textContaining('read-only'), findsOneWidget);
      expect(find.text('2 · Moderate'), findsWidgets);
      await t.scrollUntilVisible(
        find.text('Night cough'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const Key('review_submit')), findsNothing);
    });

    testWidgets('patient detail shows the record and its sessions', (t) async {
      http.handler = (o) {
        final a = auth(o);
        if (a != null) return a;
        if (o.path == ApiEndpoints.dashboard) {
          return MockReply(200, dashboardJson(patients: 1, sessions: 1));
        }
        if (o.path == ApiEndpoints.patients) {
          return MockReply(200, pageJson([patientItemJson()]));
        }
        if (o.path == ApiEndpoints.patient('p-1')) {
          return MockReply(200, patientJson(consent: 'not_recorded'));
        }
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([sessionJson()]));
        }
        return const MockReply(404);
      };
      await launch(t);
      await tap(t, nav('Patients'));
      expect(find.textContaining('1 patient'), findsOneWidget);
      await tap(t, find.byKey(const Key('patient_p-1')));
      expect(find.text('Patient LS-0142'), findsOneWidget);
      expect(find.text('HSP-22904'), findsOneWidget);
      expect(find.textContaining('Consent not recorded.'), findsOneWidget);
      expect(
        http.requests.any((r) => r.queryParameters['patient_id'] == 'p-1'),
        isTrue,
      );
      expect(find.text('Resume'), findsOneWidget);
    });
  });

  group('patient check-in', () {
    testWidgets('start creates a session for the patient, no patient_id', (
      t,
    ) async {
      http.handler = (o) {
        final a = auth(o, role: 'patient');
        if (a != null) return a;
        if (o.path == ApiEndpoints.sessions && o.method == 'POST') {
          return MockReply(201, sessionJson());
        }
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([]));
        }
        if (o.path == ApiEndpoints.session('s-1')) {
          return MockReply(200, sessionJson());
        }
        return const MockReply(404);
      };
      await launch(t);
      expect(find.text('Not done yet'), findsOneWidget);
      await tap(t, find.byKey(const Key('checkin_start')));
      expect(bodyOf(ApiEndpoints.sessions, method: 'POST'), isEmpty);
      expect(find.text('Your check-in'), findsOneWidget);
      expect(find.text('0 of 3 required done'), findsOneWidget);
    });

    testWidgets('today\'s draft is resumed instead of starting another', (
      t,
    ) async {
      http.handler = (o) {
        final a = auth(o, role: 'patient');
        if (a != null) return a;
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([sessionJson()]));
        }
        return const MockReply(404);
      };
      await launch(t);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.byKey(const Key('checkin_continue')), findsOneWidget);
      expect(find.byKey(const Key('checkin_start')), findsNothing);
      expect(find.text('Not finished'), findsOneWidget);
    });

    testWidgets('a completed check-in today still lets the patient start '
        'another', (t) async {
      http.handler = (o) {
        final a = auth(o, role: 'patient');
        if (a != null) return a;
        if (o.path == ApiEndpoints.sessions && o.method == 'POST') {
          return MockReply(201, sessionJson(id: 's-2'));
        }
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([sessionJson(status: 'completed')]));
        }
        if (o.path == ApiEndpoints.session('s-2')) {
          return MockReply(200, sessionJson(id: 's-2'));
        }
        return const MockReply(404);
      };
      await launch(t);
      expect(find.text('Done today'), findsOneWidget);
      expect(find.byKey(const Key('checkin_view_done')), findsOneWidget);
      expect(find.text('Start another check-in'), findsOneWidget);
      await tap(t, find.byKey(const Key('checkin_start')));
      expect(
        http.requests.where(
          (r) => r.path == ApiEndpoints.sessions && r.method == 'POST',
        ),
        hasLength(1),
      );
      expect(find.text('Your check-in'), findsOneWidget);
    });

    testWidgets('a draft from yesterday is not offered again', (t) async {
      final old = sessionJson()
        ..['started_at'] = DateTime.now()
            .subtract(const Duration(days: 1))
            .toUtc()
            .toIso8601String();
      http.handler = (o) {
        final a = auth(o, role: 'patient');
        if (a != null) return a;
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([old]));
        }
        return const MockReply(404);
      };
      await launch(t);
      expect(find.text('Not done yet'), findsOneWidget);
      expect(find.byKey(const Key('checkin_start')), findsOneWidget);
      expect(find.byKey(const Key('checkin_continue')), findsNothing);
    });

    testWidgets('removing today\'s draft lets the patient start again', (
      t,
    ) async {
      http.handler = (o) {
        final a = auth(o, role: 'patient');
        if (a != null) return a;
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([sessionJson()]));
        }
        if (o.path == ApiEndpoints.session('s-1')) {
          return MockReply(200, sessionJson());
        }
        return const MockReply(404);
      };
      await launch(t);
      await tap(t, find.byKey(const Key('checkin_continue')));
      await tap(
        t,
        find.byKey(const Key('overview_remove'), skipOffstage: false),
      );
      await tap(t, find.byKey(const Key('overview_remove_confirm')));
      expect(find.text('Not done yet'), findsOneWidget);
      expect(find.byKey(const Key('checkin_start')), findsOneWidget);
      expect(
        http.requests.where((r) => r.method == 'DELETE'),
        isEmpty,
        reason: 'the API has no session delete; the draft is hidden locally',
      );
    });

    testWidgets('consent is recorded before the first check-in', (t) async {
      var consent = 'not_recorded';
      http.handler = (o) {
        final a = auth(o, role: 'patient');
        if (a != null) return a;
        if (o.path == ApiEndpoints.myPatientRecord && o.method == 'PATCH') {
          consent = 'given';
          return MockReply(200, patientJson(consent: consent));
        }
        if (o.path == ApiEndpoints.myPatientRecord) {
          return MockReply(200, patientJson(consent: consent));
        }
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([]));
        }
        return const MockReply(404);
      };
      await launch(t);
      expect(
        find.textContaining('Your research consent is needed first.'),
        findsOne,
      );
      expect(find.byKey(const Key('checkin_start')), findsNothing);

      // Nothing is sent until the box is ticked.
      await tap(t, find.byKey(const Key('checkin_consent_give')));
      expect(http.requests.any((r) => r.method == 'PATCH'), isFalse);

      await tap(t, find.byKey(const Key('checkin_consent')));
      await tap(t, find.byKey(const Key('checkin_consent_give')));
      expect(bodyOf(ApiEndpoints.myPatientRecord, method: 'PATCH'), {
        'consent_status': 'given',
      });
      expect(find.byKey(const Key('checkin_consent')), findsNothing);
      expect(find.byKey(const Key('checkin_start')), findsOneWidget);
    });

    testWidgets('a consent refusal on start shows the consent step', (t) async {
      var meCalls = 0;
      http.handler = (o) {
        final a = auth(o, role: 'patient');
        if (a != null) return a;
        if (o.path == ApiEndpoints.myPatientRecord) {
          // The first read fails, so the app does not know yet.
          return meCalls++ == 0
              ? const MockReply(404)
              : MockReply(200, patientJson(consent: 'withdrawn'));
        }
        if (o.path == ApiEndpoints.sessions && o.method == 'POST') {
          return const MockReply(403, {
            'detail':
                'Research consent must be recorded before collecting data.',
          });
        }
        if (o.path == ApiEndpoints.sessions) {
          return MockReply(200, pageJson([]));
        }
        return const MockReply(404);
      };
      await launch(t);
      await tap(t, find.byKey(const Key('checkin_start')));
      expect(
        find.textContaining('You withdrew your research consent.'),
        findsOne,
      );
      expect(find.textContaining('Check-in not started.'), findsNothing);
    });
  });
}
