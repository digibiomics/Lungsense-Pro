import '../../../../core/utils/paged.dart';
import '../entities/collection_session.dart';
import '../entities/dashboard_stats.dart';
import '../entities/recording.dart';
import '../entities/symptoms.dart';

/// Documented `/api/v1/collection` operations (doctor and patient). Methods
/// throw `Failure`; [completeSession] also throws [IncompleteSession].
abstract interface class CollectionRepository {
  /// Doctors pass [patientId]; for patients the server uses their own record.
  Future<CollectionSession> createSession({String? patientId});

  /// Sessions of the doctor's patients, or the patient's own sessions.
  Future<Paged<SessionSummary>> listSessions({
    SessionStatus? status,
    String? patientId,
    int offset = 0,
    int limit = 50,
  });

  Future<CollectionSession> getSession(String id);
  Future<CollectionSession> updateNotes(String id, String? notes);
  Future<CollectionSession> completeSession(String id);

  /// Null when no ratings were saved yet.
  Future<SymptomRatings?> getSymptoms(String sessionId);
  Future<SymptomRatings> saveSymptoms(String sessionId, SymptomRatings r);

  /// Upload URL → direct upload → complete. Returns the server's record.
  Future<AudioRecording> uploadAudio(
    String sessionId,
    RecordingType type,
    LocalFile file, {
    UploadProgress? onProgress,
  });
  Future<AudioRecording> getAudio(String id);
  Future<void> deleteAudio(String id);
  Future<Uri> audioDownloadUrl(String id);

  Future<XrayImage> uploadXray(
    String sessionId,
    LocalFile file, {
    XrayView? view,
    DateTime? takenOn,
    UploadProgress? onProgress,
  });
  Future<void> deleteXray(String id);
  Future<Uri> xrayDownloadUrl(String id);

  Future<DashboardStats> dashboard({DateTime? from, DateTime? to});
}
