import 'package:equatable/equatable.dart';

import 'collection_session.dart';

/// `RecentSession` of the doctor dashboard.
class RecentSession extends Equatable {
  const RecentSession({
    required this.sessionId,
    required this.patientId,
    required this.studyId,
    required this.status,
    this.startedAt,
    this.completedAt,
  });

  final String sessionId;
  final String patientId;
  final String studyId;
  final SessionStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  @override
  List<Object?> get props => [
    sessionId,
    patientId,
    studyId,
    status,
    startedAt,
    completedAt,
  ];
}

/// `DoctorDashboardOut`.
class DashboardStats extends Equatable {
  const DashboardStats({
    required this.patientsRegistered,
    required this.patientsRecorded,
    required this.sessionsTotal,
    required this.sessionsCompleted,
    required this.sessionsDraft,
    required this.coughRecordings,
    required this.breathingRecordings,
    required this.xrayImages,
    required this.recordingsFailedQc,
    required this.draftsMissingItems,
    required this.incompleteUploads,
    required this.recent,
  });

  final int patientsRegistered;
  final int patientsRecorded;
  final int sessionsTotal;
  final int sessionsCompleted;
  final int sessionsDraft;
  final int coughRecordings;
  final int breathingRecordings;
  final int xrayImages;
  final int recordingsFailedQc;
  final int draftsMissingItems;
  final int incompleteUploads;
  final List<RecentSession> recent;

  bool get isEmpty => patientsRegistered == 0 && sessionsTotal == 0;

  @override
  List<Object?> get props => [
    patientsRegistered,
    patientsRecorded,
    sessionsTotal,
    sessionsCompleted,
    sessionsDraft,
    coughRecordings,
    breathingRecordings,
    xrayImages,
    recordingsFailedQc,
    draftsMissingItems,
    incompleteUploads,
    recent,
  ];
}
