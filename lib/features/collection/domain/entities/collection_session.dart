import 'package:equatable/equatable.dart';

import 'recording.dart';
import 'symptoms.dart';

/// `status` of a session. The API documents `status=draft` as the
/// resumable state; anything not recognised is shown as unknown and never
/// treated as submitted.
enum SessionStatus {
  draft,
  completed,
  unknown;

  static SessionStatus fromApi(String? v) => switch (v?.toLowerCase()) {
    'draft' || 'in_progress' => SessionStatus.draft,
    'completed' || 'complete' || 'submitted' => SessionStatus.completed,
    _ => SessionStatus.unknown,
  };
}

/// Required items of a session (`missing_modalities`).
enum CollectionStep {
  cough('cough', 'Cough recording'),
  breathing('breathing', 'Breathing recording'),
  symptoms('symptoms', 'Symptoms');

  const CollectionStep(this.api, this.label);
  final String api;
  final String label;

  static CollectionStep? fromApi(String v) {
    for (final s in values) {
      if (s.api == v.toLowerCase()) return s;
    }
    return null;
  }
}

/// `SessionCounts`.
class SessionCounts extends Equatable {
  const SessionCounts({
    this.cough = 0,
    this.breathing = 0,
    this.xrays = 0,
    this.symptomsRecorded = false,
  });

  final int cough;
  final int breathing;
  final int xrays;
  final bool symptomsRecorded;

  /// Required steps done (cough, breathing, symptoms), 0–3.
  int get requiredDone =>
      (cough > 0 ? 1 : 0) +
      (breathing > 0 ? 1 : 0) +
      (symptomsRecorded ? 1 : 0);

  @override
  List<Object?> get props => [cough, breathing, xrays, symptomsRecorded];
}

/// A session row (`SessionOut`).
class SessionSummary extends Equatable {
  const SessionSummary({
    required this.id,
    required this.patientId,
    required this.studyId,
    required this.status,
    required this.counts,
    this.source,
    this.notes,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final String studyId;
  final SessionStatus status;
  final SessionCounts counts;

  /// `collection_source` (who collected it), shown as given.
  final String? source;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  bool get isDraft => status == SessionStatus.draft;
  bool get isCompleted => status == SessionStatus.completed;

  @override
  List<Object?> get props => [
    id,
    patientId,
    studyId,
    status,
    counts,
    source,
    notes,
    startedAt,
    completedAt,
    updatedAt,
  ];
}

/// A full session (`SessionDetailOut`).
class CollectionSession extends Equatable {
  const CollectionSession({
    required this.summary,
    required this.patientName,
    required this.recordings,
    required this.xrays,
    required this.missing,
    this.symptoms,
  });

  final SessionSummary summary;
  final String? patientName;
  final SymptomRatings? symptoms;
  final List<AudioRecording> recordings;
  final List<XrayImage> xrays;

  /// Required items the server still needs before it can complete.
  final List<CollectionStep> missing;

  String get id => summary.id;
  String get studyId => summary.studyId;
  bool get isDraft => summary.isDraft;
  bool get isCompleted => summary.isCompleted;

  /// The newest recording of [type] whose upload finished.
  AudioRecording? latest(RecordingType type) {
    final list = recordings.where((r) => r.type == type && r.isUploaded);
    if (list.isEmpty) return null;
    return list.reduce(
      (a, b) => (b.createdAt ?? DateTime(0)).isAfter(a.createdAt ?? DateTime(0))
          ? b
          : a,
    );
  }

  bool isDone(CollectionStep step) => !missing.contains(step);

  @override
  List<Object?> get props => [
    summary,
    patientName,
    symptoms,
    recordings,
    xrays,
    missing,
  ];
}

/// `409 incomplete_session` from `POST .../complete`.
class IncompleteSession implements Exception {
  const IncompleteSession(this.missing);
  final List<CollectionStep> missing;
}
