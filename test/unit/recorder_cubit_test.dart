import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/core/utils/paged.dart';
import 'package:lungsense_pro/features/collection/data/models/collection_models.dart';
import 'package:lungsense_pro/features/collection/domain/entities/collection_session.dart';
import 'package:lungsense_pro/features/collection/domain/entities/dashboard_stats.dart';
import 'package:lungsense_pro/features/collection/domain/entities/recording.dart';
import 'package:lungsense_pro/features/collection/domain/entities/symptoms.dart';
import 'package:lungsense_pro/features/collection/domain/repositories/collection_repository.dart';
import 'package:lungsense_pro/features/collection/presentation/cubit/recorder_cubit.dart';

import '../helpers/collection_fakes.dart';

/// Hand-written fake repository: no HTTP, scripted answers.
class FakeRepo implements CollectionRepository {
  CollectionSession session = CollectionModels.sessionFromJson(sessionJson());
  List<AudioRecording Function()> uploads = [];
  List<AudioRecording> polls = [];
  final uploaded = <(RecordingType, LocalFile)>[];
  final deleted = <String>[];
  int getAudioCalls = 0;

  @override
  Future<CollectionSession> getSession(String id) async => session;

  @override
  Future<AudioRecording> uploadAudio(
    String sessionId,
    RecordingType type,
    LocalFile file, {
    UploadProgress? onProgress,
  }) async {
    uploaded.add((type, file));
    onProgress?.call(.5);
    onProgress?.call(1);
    return uploads.removeAt(0)();
  }

  @override
  Future<AudioRecording> getAudio(String id) async {
    getAudioCalls++;
    return polls.isEmpty ? recording(qc: null) : polls.removeAt(0);
  }

  @override
  Future<void> deleteAudio(String id) async => deleted.add(id);

  @override
  Future<Uri> audioDownloadUrl(String id) async =>
      Uri.parse('https://storage.example.com/$id');

  // Unused members of the interface.
  @override
  Future<CollectionSession> createSession({String? patientId}) =>
      throw UnimplementedError();
  @override
  Future<Paged<SessionSummary>> listSessions({
    SessionStatus? status,
    String? patientId,
    int offset = 0,
    int limit = 50,
  }) => throw UnimplementedError();
  @override
  Future<CollectionSession> updateNotes(String id, String? notes) =>
      throw UnimplementedError();
  @override
  Future<CollectionSession> completeSession(String id) =>
      throw UnimplementedError();
  @override
  Future<SymptomRatings?> getSymptoms(String sessionId) =>
      throw UnimplementedError();
  @override
  Future<SymptomRatings> saveSymptoms(String sessionId, SymptomRatings r) =>
      throw UnimplementedError();
  @override
  Future<XrayImage> uploadXray(
    String sessionId,
    LocalFile file, {
    XrayView? view,
    DateTime? takenOn,
    UploadProgress? onProgress,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteXray(String id) => throw UnimplementedError();
  @override
  Future<Uri> xrayDownloadUrl(String id) => throw UnimplementedError();
  @override
  Future<DashboardStats> dashboard({DateTime? from, DateTime? to}) =>
      throw UnimplementedError();
}

AudioRecording recording({
  String id = 'a-new',
  bool? qc = true,
  String? reason,
  String type = 'cough',
}) => CollectionModels.audioFromJson(
  audioJson(id: id, qc: qc, reason: reason, type: type),
);

void main() {
  late FakeRepo repo;
  late FakeAudioCapture capture;
  late FakeAudioInspector inspector;
  late FakeFilePicking files;

  setUp(() {
    repo = FakeRepo();
    capture = FakeAudioCapture();
    inspector = FakeAudioInspector();
    files = FakeFilePicking();
  });

  RecorderCubit build({RecordingType type = RecordingType.cough}) =>
      RecorderCubit(
        repository: repo,
        capture: capture,
        inspector: inspector,
        playback: FakeAudioPlayback(),
        files: files,
        sessionId: 's-1',
        type: type,
      );

  /// Runs [body] in fake time, then lets pending work settle.
  void run(void Function(FakeAsync a, RecorderCubit c) body) {
    fakeAsync((a) {
      final c = build();
      c.load();
      a.flushMicrotasks();
      body(a, c);
      c.close();
      a.flushMicrotasks();
    });
  }

  test('starts idle with nothing recorded, Continue disabled', () {
    run((a, c) {
      expect(c.state.phase, RecorderPhase.idle);
      expect(c.state.canContinue, isFalse);
    });
  });

  test('stopping before 12 s is too short and uploads nothing', () {
    run((a, c) {
      c.toggleRecord();
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.recording);
      a.elapse(const Duration(seconds: 7, milliseconds: 200));
      c.toggleRecord();
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.tooShort);
      expect(c.state.elapsed, const Duration(seconds: 7, milliseconds: 200));
      expect(capture.cancels, 1);
      expect(repo.uploaded, isEmpty);
    });
  });

  test('auto-stops at 15 s, uploads, and passes on the server verdict', () {
    repo.uploads = [() => recording()];
    run((a, c) {
      c.toggleRecord();
      a.flushMicrotasks();
      a.elapse(const Duration(seconds: 16));
      a.flushMicrotasks();
      expect(c.state.elapsed, RecordingType.cough.maxDuration);
      expect(repo.uploaded.single.$1, RecordingType.cough);
      expect(c.state.phase, RecorderPhase.passed);
      expect(c.state.canContinue, isTrue);
    });
  });

  test('quality failure shows the server reason; redo deletes it', () {
    repo.uploads = [
      () => recording(id: 'bad', qc: false, reason: 'Too much noise.'),
    ];
    run((a, c) {
      c.toggleRecord();
      a.flushMicrotasks();
      a.elapse(const Duration(seconds: 13));
      c.toggleRecord();
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.qualityFailed);
      expect(c.state.recording!.qcReason, 'Too much noise.');
      expect(c.state.canContinue, isFalse);
      c.rerecord();
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.idle);
      expect(repo.deleted, ['bad']);
    });
  });

  test('a 41 s imported cough file is refused before upload', () {
    files.audio = const LocalFile(
      path: 'x.m4a',
      name: 'x.m4a',
      sizeBytes: 10,
      contentType: 'audio/mp4',
    );
    inspector.duration = const Duration(seconds: 41);
    run((a, c) {
      c.importFile();
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.importInvalid);
      expect(c.state.elapsed.inSeconds, 41);
      expect(repo.uploaded, isEmpty);
    });
  });

  test('a valid import uploads the picked file', () {
    files.audio = const LocalFile(
      path: 'ok.wav',
      name: 'ok.wav',
      sizeBytes: 10,
      contentType: 'audio/wav',
    );
    inspector.duration = const Duration(seconds: 13);
    repo.uploads = [() => recording()];
    run((a, c) {
      c.importFile();
      a.flushMicrotasks();
      expect(repo.uploaded.single.$2.name, 'ok.wav');
      expect(c.state.phase, RecorderPhase.passed);
      expect(c.state.fromFile, isTrue);
    });
  });

  test('upload failure keeps the file; Retry uploads it again', () {
    repo.uploads = [
      () => throw const Failure(kind: FailureKind.network),
      () => recording(),
    ];
    run((a, c) {
      c.toggleRecord();
      a.flushMicrotasks();
      a.elapse(const Duration(seconds: 15));
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.uploadFailed);
      expect(c.state.file, isNotNull);
      c.retryUpload();
      a.flushMicrotasks();
      expect(repo.uploaded, hasLength(2));
      expect(c.state.phase, RecorderPhase.passed);
    });
  });

  test('pending quality check is polled until the server answers', () {
    repo.uploads = [() => recording(qc: null)];
    repo.polls = [recording(qc: null), recording(qc: true)];
    run((a, c) {
      c.toggleRecord();
      a.flushMicrotasks();
      a.elapse(const Duration(seconds: 15));
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.checking);
      expect(c.state.canContinue, isFalse);
      a.elapse(const Duration(seconds: 5));
      expect(c.state.phase, RecorderPhase.passed);
      expect(repo.getAudioCalls, 2);
    });
  });

  test('a check that never finishes ends in checkPending', () {
    repo.uploads = [() => recording(qc: null)];
    run((a, c) {
      c.toggleRecord();
      a.flushMicrotasks();
      a.elapse(const Duration(seconds: 15));
      a.elapse(const Duration(seconds: 25));
      expect(c.state.phase, RecorderPhase.checkPending);
      expect(c.state.canContinue, isTrue);
    });
  });

  test('a new passed recording replaces the earlier one', () {
    repo.session = CollectionModels.sessionFromJson(
      sessionJson(audio: [audioJson(id: 'old')]),
    );
    repo.uploads = [() => recording(id: 'new')];
    run((a, c) {
      expect(c.state.phase, RecorderPhase.passed);
      expect(c.state.recording!.id, 'old');
      c.rerecord();
      a.flushMicrotasks();
      expect(repo.deleted, isEmpty);
      c.toggleRecord();
      a.flushMicrotasks();
      a.elapse(const Duration(seconds: 15));
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.passed);
      expect(repo.deleted, ['old']);
    });
  });

  test('microphone refused shows micDenied', () {
    capture.permission = false;
    run((a, c) {
      c.toggleRecord();
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.micDenied);
      expect(capture.starts, 0);
    });
  });

  test('breathing uses 25–30 s', () {
    fakeAsync((a) {
      final c = build(type: RecordingType.breathing)..load();
      a.flushMicrotasks();
      c.toggleRecord();
      a.flushMicrotasks();
      a.elapse(const Duration(seconds: 20));
      c.toggleRecord();
      a.flushMicrotasks();
      expect(c.state.phase, RecorderPhase.tooShort);
      c.close();
      a.flushMicrotasks();
    });
  });
}
