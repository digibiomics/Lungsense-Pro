import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/core/network/api_endpoints.dart';
import 'package:lungsense_pro/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:lungsense_pro/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:lungsense_pro/features/admin/domain/entities/admin_user.dart';
import 'package:lungsense_pro/features/authentication/domain/entities/app_user.dart';
import 'package:lungsense_pro/features/collection/data/datasources/collection_remote_data_source.dart';
import 'package:lungsense_pro/features/collection/data/models/collection_models.dart';
import 'package:lungsense_pro/features/collection/domain/entities/collection_session.dart';
import 'package:lungsense_pro/features/collection/domain/entities/recording.dart';
import 'package:lungsense_pro/features/collection/domain/entities/symptoms.dart';
import 'package:lungsense_pro/features/patients/data/datasources/patient_remote_data_source.dart';
import 'package:lungsense_pro/features/patients/data/models/patient_models.dart';
import 'package:lungsense_pro/features/patients/domain/entities/patient.dart';

import '../helpers/collection_fakes.dart';
import '../helpers/fakes.dart';

// Request bodies and parsers against the documented schemas
// (docs/openapi_snapshot.json). HTTP is MOCKED.
void main() {
  Map<String, dynamic> body(RequestOptions r) {
    final d = r.data;
    return (d is String ? jsonDecode(d) : d) as Map<String, dynamic>;
  }

  group('collection models', () {
    test('session detail parses counts, symptoms, missing items', () {
      final s = CollectionModels.sessionFromJson(
        sessionJson(audio: [audioJson()], symptoms: symptomsJson(2)),
      );
      expect(s.isDraft, isTrue);
      expect(s.studyId, 'LS-0142');
      expect(s.missing, [CollectionStep.breathing]);
      expect(s.latest(RecordingType.cough)!.qcPassed, isTrue);
      expect(s.symptoms!.isComplete, isTrue);
      expect(s.symptoms!.highest, 2);
      expect(s.summary.counts.requiredDone, 2);
    });

    test('unknown status is never treated as completed', () {
      final s = CollectionModels.sessionFromJson(sessionJson(status: 'weird'));
      expect(s.summary.status, SessionStatus.unknown);
      expect(s.isCompleted, isFalse);
    });

    test('symptoms body has all ten keys and refuses partial forms', () {
      var r = SymptomRatings.empty;
      for (final k in SymptomKey.values) {
        r = r.withRating(k, 0);
      }
      final b = CollectionModels.symptomsBody(r);
      expect(b.keys.toSet(), SymptomKey.values.map((k) => k.api).toSet());
      expect(
        () => CollectionModels.symptomsBody(
          SymptomRatings.empty.withRating(SymptomKey.fever, 1),
        ),
        throwsArgumentError,
      );
    });

    test('409 incomplete_session lists the missing items', () {
      final e = CollectionModels.incompleteFrom(409, {
        'detail': {
          'code': 'incomplete_session',
          'missing': ['symptoms', 'breathing'],
        },
      });
      expect(e!.missing, [CollectionStep.symptoms, CollectionStep.breathing]);
      expect(CollectionModels.incompleteFrom(400, {'detail': 'x'}), isNull);
    });

    test('dashboard parses counts and recent activity', () {
      final d = CollectionModels.dashboardFromJson(
        dashboardJson(
          patients: 24,
          sessions: 31,
          drafts: 2,
          recent: [
            {
              'session_id': 's-9',
              'patient_id': 'p-9',
              'study_id': 'LS-0141',
              'patient_name': null,
              'status': 'completed',
              'started_at': '2026-10-27T05:00:00Z',
              'completed_at': '2026-10-27T05:20:00Z',
            },
          ],
        ),
      );
      expect(d.patientsRegistered, 24);
      expect(d.sessionsDraft, 2);
      expect(d.recent.single.studyId, 'LS-0141');
      expect(d.isEmpty, isFalse);
    });
  });

  group('uploads', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('ls_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('audio: upload-url body, presigned POST without token, '
        'then complete', () async {
      final file = File('${dir.path}/c.m4a')..writeAsBytesSync([1, 2, 3, 4]);
      final http = MockHttpAdapter((o) {
        if (o.path == ApiEndpoints.audioUploadUrl('s-1')) {
          return const MockReply(201, {
            'id': 'a-1',
            'upload': {
              'url': 'https://storage.example.com/bucket',
              'fields': {'key': 'audio/a-1.m4a', 'policy': 'p'},
            },
            'expires_in_seconds': 600,
            'max_bytes': 1000000,
            'complete_url': '/api/v1/collection/audio/a-1/complete',
          });
        }
        if (o.uri.toString() == 'https://storage.example.com/bucket') {
          return const MockReply(204);
        }
        if (o.path == ApiEndpoints.completeAudio('a-1')) {
          return MockReply(200, audioJson(id: 'a-1'));
        }
        return const MockReply(404);
      });
      final api = mockDio(http)
        ..options.headers['Authorization'] = 'Bearer secret';
      final uploads = Dio()..httpClientAdapter = http;
      final ds = CollectionRemoteDataSource(api, uploads);
      final progress = <double>[];

      final rec = await ds.uploadAudio(
        's-1',
        RecordingType.cough,
        LocalFile(
          path: file.path,
          name: 'c.m4a',
          sizeBytes: 4,
          contentType: 'audio/mp4',
        ),
        progress.add,
      );

      expect(body(http.requests.first), {
        'recording_type': 'cough',
        'content_type': 'audio/mp4',
        'file_size_bytes': 4,
      });
      final post = http.requests[1];
      expect(post.uri.toString(), 'https://storage.example.com/bucket');
      expect(post.headers['Authorization'], isNull);
      final form = post.data as FormData;
      expect(form.fields.map((f) => f.key), ['key', 'policy']);
      expect(form.files.single.key, 'file');
      expect(http.requests.last.path, ApiEndpoints.completeAudio('a-1'));
      expect(rec.qcPassed, isTrue);
    });

    test('a file over max_bytes is refused before uploading', () async {
      final file = File('${dir.path}/x.png')..writeAsBytesSync([1, 2, 3]);
      final http = MockHttpAdapter(
        (o) => const MockReply(201, {
          'id': 'x-1',
          'upload': {'url': 'https://storage.example.com/b', 'fields': {}},
          'expires_in_seconds': 600,
          'max_bytes': 2,
          'complete_url': '',
        }),
      );
      final ds = CollectionRemoteDataSource(mockDio(http), Dio());
      await expectLater(
        ds.uploadXray(
          's-1',
          LocalFile(
            path: file.path,
            name: 'x.png',
            sizeBytes: 3,
            contentType: 'image/png',
          ),
          XrayView.pa,
          DateTime(2026, 10, 27),
          null,
        ),
        throwsA(isA<Failure>()),
      );
      expect(body(http.requests.single), {
        'content_type': 'image/png',
        'file_size_bytes': 3,
        'original_filename': 'x.png',
        'view': 'PA',
        'taken_on': '2026-10-27',
      });
    });

    test('complete: 409 becomes IncompleteSession', () async {
      final http = MockHttpAdapter(
        (o) => const MockReply(409, {
          'detail': {
            'code': 'incomplete_session',
            'message': 'Missing items',
            'missing': ['cough'],
          },
        }),
      );
      final ds = CollectionRemoteDataSource(mockDio(http), Dio());
      await expectLater(
        ds.completeSession('s-1'),
        throwsA(
          isA<IncompleteSession>().having((e) => e.missing, 'missing', [
            CollectionStep.cough,
          ]),
        ),
      );
    });

    test('session list filters use the documented status values', () async {
      // Spec: status matches ^(draft|complete)$; "completed" is a 422.
      final http = MockHttpAdapter((o) => MockReply(200, pageJson([])));
      final ds = CollectionRemoteDataSource(mockDio(http), Dio());
      for (final s in SessionStatus.values) {
        await ds.listSessions(status: s, offset: 0, limit: 20);
      }
      await ds.listSessions(offset: 0, limit: 20);
      expect(http.requests.map((r) => r.queryParameters['status']).toList(), [
        'draft',
        'complete',
        null, // unknown
        null, // no filter
      ]);
    });
  });

  group('patients', () {
    const input = PatientInput(
      externalId: ' HSP-22871 ',
      ageYears: 54,
      sex: PatientSex.male,
      consent: ConsentStatus.given,
      relevantHistory: '  ',
    );

    test('create body uses the documented fields only', () {
      expect(PatientModels.body(input, allowDuplicate: false), {
        'external_id': 'HSP-22871',
        'age_years': 54,
        'sex': 'male',
        'consent_status': 'given',
        'relevant_history': null,
        'allow_duplicate': false,
      });
      expect(PatientModels.body(input).containsKey('allow_duplicate'), false);
    });

    test('409 possible_duplicate is read with its matches', () async {
      final http = MockHttpAdapter(
        (o) => const MockReply(409, {
          'detail': {
            'code': 'possible_duplicate',
            'message': 'Possible duplicate',
            'matches': [
              {
                'id': 'p-119',
                'study_id': 'LS-0119',
                'external_id': 'HSP-22871',
              },
            ],
          },
        }),
      );
      final ds = PatientRemoteDataSource(mockDio(http));
      await expectLater(
        ds.create(input, false),
        throwsA(
          isA<PossibleDuplicate>().having(
            (d) => d.matches.single.studyId,
            'study',
            'LS-0119',
          ),
        ),
      );
    });

    test('list sends search and paging', () async {
      final http = MockHttpAdapter(
        (o) => MockReply(200, pageJson([patientItemJson()], total: 24)),
      );
      final page = await PatientRemoteDataSource(mockDio(http))
          .list(search: 'LS-01');
      expect(http.requests.single.queryParameters, {
        'search': 'LS-01',
        'limit': 50,
        'offset': 0,
      });
      expect(page.total, 24);
      expect(page.items.single.studyId, 'LS-0142');
    });
  });

  group('admin users', () {
    test('status change sends the documented StatusUpdate body', () async {
      final http = MockHttpAdapter(
        (o) => const MockReply(200, {
          'id': 'u-3',
          'email': 'o.lone@example.com',
          'full_name': 'Dr. Omar Lone',
          'role': 'doctor',
          'account_status': 'suspended',
          'created_at': null,
        }),
      );
      final repo = AdminRepositoryImpl(AdminRemoteDataSource(mockDio(http)));
      final u = await repo.setUserStatus(
        'u-3',
        UserStatusChange.suspended,
        reason: 'Left the study',
      );
      final r = http.requests.single;
      expect(r.method, 'PATCH');
      expect(r.path, ApiEndpoints.userStatus('u-3'));
      expect(body(r), {
        'account_status': 'suspended',
        'reason': 'Left the study',
      });
      expect(u.status, AccountStatus.suspended);
      expect(u.canReactivate, isTrue);
    });

    test('approval tabs read pending, active and rejected', () async {
      final http = MockHttpAdapter((o) => MockReply(200, pageJson([])));
      await AdminRepositoryImpl(AdminRemoteDataSource(mockDio(http)))
          .listDoctorApplications();
      expect(http.requests.map((r) => r.queryParameters['status']).toSet(), {
        'pending_approval',
        'active',
        'rejected',
      });
    });
  });
}
