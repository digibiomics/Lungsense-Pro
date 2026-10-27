import '../../../../core/utils/paged.dart';
import '../../domain/entities/collection_session.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/symptoms.dart';
import '../../domain/repositories/collection_repository.dart';
import '../datasources/collection_remote_data_source.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  const CollectionRepositoryImpl(this._remote);
  final CollectionRemoteDataSource _remote;

  @override
  Future<CollectionSession> createSession({String? patientId}) =>
      _remote.createSession(patientId);

  @override
  Future<Paged<SessionSummary>> listSessions({
    SessionStatus? status,
    String? patientId,
    int offset = 0,
    int limit = 50,
  }) => _remote.listSessions(
    status: status,
    patientId: patientId,
    offset: offset,
    limit: limit,
  );

  @override
  Future<CollectionSession> getSession(String id) => _remote.getSession(id);

  @override
  Future<CollectionSession> updateNotes(String id, String? notes) {
    final t = notes?.trim();
    return _remote.updateNotes(id, t == null || t.isEmpty ? null : t);
  }

  @override
  Future<CollectionSession> completeSession(String id) =>
      _remote.completeSession(id);

  @override
  Future<SymptomRatings?> getSymptoms(String sessionId) =>
      _remote.getSymptoms(sessionId);

  @override
  Future<SymptomRatings> saveSymptoms(String sessionId, SymptomRatings r) =>
      _remote.saveSymptoms(sessionId, r);

  @override
  Future<AudioRecording> uploadAudio(
    String sessionId,
    RecordingType type,
    LocalFile file, {
    UploadProgress? onProgress,
  }) => _remote.uploadAudio(sessionId, type, file, onProgress);

  @override
  Future<AudioRecording> getAudio(String id) => _remote.getAudio(id);

  @override
  Future<void> deleteAudio(String id) => _remote.deleteAudio(id);

  @override
  Future<Uri> audioDownloadUrl(String id) => _remote.audioDownloadUrl(id);

  @override
  Future<XrayImage> uploadXray(
    String sessionId,
    LocalFile file, {
    XrayView? view,
    DateTime? takenOn,
    UploadProgress? onProgress,
  }) => _remote.uploadXray(sessionId, file, view, takenOn, onProgress);

  @override
  Future<void> deleteXray(String id) => _remote.deleteXray(id);

  @override
  Future<Uri> xrayDownloadUrl(String id) => _remote.xrayDownloadUrl(id);

  @override
  Future<DashboardStats> dashboard({DateTime? from, DateTime? to}) =>
      _remote.dashboard(from, to);
}
