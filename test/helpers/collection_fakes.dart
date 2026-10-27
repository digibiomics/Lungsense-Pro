// TEST DOUBLES ONLY. Nothing here is used by the production code path.
import 'dart:async';

import 'package:lungsense_pro/app/di.dart';
import 'package:lungsense_pro/features/collection/domain/entities/recording.dart';
import 'package:lungsense_pro/features/collection/domain/services/device_services.dart';

/// Fake microphone: records nothing, returns [file] on stop.
class FakeAudioCapture implements AudioCapture {
  FakeAudioCapture({this.permission = true, this.file});
  bool permission;
  LocalFile? file;
  int starts = 0;
  int cancels = 0;
  final _level = StreamController<double>.broadcast();

  @override
  Stream<double> get level => _level.stream;

  void emitLevel(double v) => _level.add(v);

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Future<void> start() async => starts++;

  @override
  Future<LocalFile?> stop() async =>
      file ??
      const LocalFile(
        path: 'rec.m4a',
        name: 'rec.m4a',
        sizeBytes: 1000,
        contentType: 'audio/mp4',
      );

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<void> dispose() => _level.close();
}

class FakeAudioInspector implements AudioInspector {
  Duration? duration;

  @override
  Future<Duration?> durationOf(LocalFile file) async => duration;
}

class FakeAudioPlayback implements AudioPlayback {
  final _playing = StreamController<bool>.broadcast();
  final played = <String>[];

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<void> playFile(String path) async {
    played.add(path);
    _playing.add(true);
  }

  @override
  Future<void> playUrl(Uri url) async {
    played.add(url.toString());
    _playing.add(true);
  }

  @override
  Future<void> stop() async => _playing.add(false);

  @override
  Future<void> dispose() => _playing.close();
}

class FakeFilePicking implements FilePicking {
  LocalFile? audio;
  LocalFile? xray;

  @override
  Future<LocalFile?> pickAudio() async => audio;

  @override
  Future<LocalFile?> pickXray() async => xray;
}

class FakeLinkOpener implements LinkOpener {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

DeviceServices fakeDevices({
  FakeAudioCapture? capture,
  FakeFilePicking? files,
  FakeAudioInspector? inspector,
}) => DeviceServices(
  capture: () => capture ?? FakeAudioCapture(),
  inspector: inspector ?? FakeAudioInspector(),
  playback: FakeAudioPlayback.new,
  files: files ?? FakeFilePicking(),
  links: FakeLinkOpener(),
);

// ------------------------------------------------------------ JSON samples

Map<String, dynamic> pageJson(List<Object?> items, {int? total}) => {
  'items': items,
  'total': total ?? items.length,
  'limit': 50,
  'offset': 0,
};

Map<String, dynamic> dashboardJson({
  int patients = 0,
  int sessions = 0,
  int drafts = 0,
  List<Object?> recent = const [],
}) => {
  'date_from': null,
  'date_to': null,
  'patients_registered': patients,
  'patients_recorded': patients,
  'sessions_total': sessions,
  'sessions_completed': sessions - drafts,
  'sessions_draft': drafts,
  'cough_recordings': 0,
  'breathing_recordings': 0,
  'xray_images': 0,
  'recordings_failed_qc': 0,
  'draft_sessions_missing_items': 0,
  'incomplete_uploads': 0,
  'recent_activity': recent,
};

Map<String, dynamic> patientJson({
  String id = 'p-1',
  String studyId = 'LS-0142',
  String consent = 'given',
}) => {
  'id': id,
  'study_id': studyId,
  'full_name': null,
  'external_id': 'HSP-22904',
  'age_years': 54,
  'sex': 'male',
  'consent_status': consent,
  'consent_version': null,
  'consent_recorded_at': null,
  'is_archived': false,
  'created_at': '2026-10-21T09:00:00Z',
  'updated_at': '2026-10-21T09:00:00Z',
};

Map<String, dynamic> patientItemJson({
  String id = 'p-1',
  String studyId = 'LS-0142',
}) => {
  'id': id,
  'study_id': studyId,
  'full_name': null,
  'date_of_birth': null,
  'age_years': 54,
  'sex': 'male',
  'external_id': 'HSP-22904',
  'consent_status': 'given',
  'is_archived': false,
  'session_count': 1,
  'last_session_at': null,
};

Map<String, dynamic> audioJson({
  String id = 'a-1',
  String type = 'cough',
  bool? qc = true,
  String? reason,
  double duration = 13.8,
}) => {
  'id': id,
  'session_id': 's-1',
  'recording_type': type,
  'content_type': 'audio/mp4',
  'size_bytes': 1000,
  'upload_status': 'uploaded',
  'processing_status': qc == null ? 'pending' : 'completed',
  'qc_passed': qc,
  'qc_reason': reason,
  'duration_seconds': duration,
  'quality_score': null,
  'created_at': '2026-10-27T05:00:00Z',
  'uploaded_at': '2026-10-27T05:00:01Z',
  'processed_at': null,
};

Map<String, dynamic> symptomsJson([int value = 1]) => {
  'checkin_date': '2026-10-27',
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
  ])
    k: value,
  'id': 'sym-1',
  'session_id': 's-1',
  'created_at': null,
  'updated_at': null,
};

/// `SessionDetailOut`. [missing] defaults to what the other fields imply.
Map<String, dynamic> sessionJson({
  String id = 's-1',
  String status = 'draft',
  List<Map<String, dynamic>> audio = const [],
  Map<String, dynamic>? symptoms,
  String? notes,
  List<String>? missing,
}) {
  bool has(String t) => audio.any((a) => a['recording_type'] == t);
  return {
    'id': id,
    'patient_id': 'p-1',
    'study_id': 'LS-0142',
    'collector_user_id': 'u-1',
    'collection_source': 'doctor',
    'status': status,
    'notes': notes,
    'started_at': DateTime.now().toUtc().toIso8601String(),
    'completed_at': status == 'completed'
        ? DateTime.now().toUtc().toIso8601String()
        : null,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
    'counts': {
      'cough_recordings': has('cough') ? 1 : 0,
      'breathing_recordings': has('breathing') ? 1 : 0,
      'xray_images': 0,
      'symptoms_recorded': symptoms != null,
    },
    'patient': {'id': 'p-1', 'study_id': 'LS-0142', 'full_name': null},
    'symptoms': symptoms,
    'audio_recordings': audio,
    'xray_images': const [],
    'missing_modalities':
        missing ??
        [
          if (!has('cough')) 'cough',
          if (!has('breathing')) 'breathing',
          if (symptoms == null) 'symptoms',
        ],
  };
}
