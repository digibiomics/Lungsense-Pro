import 'package:equatable/equatable.dart';

/// `recording_type` of `AudioUploadRequest`, with the collection limits from
/// the handoff ("Collection rules"). The API does not serve these limits,
/// so they are fixed here.
enum RecordingType {
  cough('cough', 'Cough', min: 12, max: 15),
  breathing('breathing', 'Breathing', min: 25, max: 30);

  const RecordingType(
    this.api,
    this.label, {
    required this.min,
    required this.max,
  });
  final String api;
  final String label;

  /// Seconds.
  final int min;
  final int max;

  Duration get minDuration => Duration(seconds: min);
  Duration get maxDuration => Duration(seconds: max);

  static RecordingType? fromApi(String? v) {
    for (final t in values) {
      if (t.api == v) return t;
    }
    return null;
  }
}

/// `AudioRecordingOut`. Status strings are shown or compared as the server
/// sends them; only the documented `qc_*` fields drive the UI.
class AudioRecording extends Equatable {
  const AudioRecording({
    required this.id,
    required this.type,
    required this.contentType,
    required this.uploadStatus,
    required this.processingStatus,
    this.sizeBytes,
    this.qcPassed,
    this.qcReason,
    this.durationSeconds,
    this.qualityScore,
    this.createdAt,
    this.uploadedAt,
  });

  final String id;
  final RecordingType? type;
  final String contentType;
  final String uploadStatus;
  final String processingStatus;
  final int? sizeBytes;

  /// Null while the server has not checked the recording yet.
  final bool? qcPassed;
  final String? qcReason;
  final double? durationSeconds;
  final double? qualityScore;
  final DateTime? createdAt;
  final DateTime? uploadedAt;

  bool get isUploaded =>
      uploadedAt != null ||
      const {'uploaded', 'complete', 'completed'}.contains(uploadStatus);

  /// The server could not run its quality check.
  bool get processingFailed =>
      const {'failed', 'error'}.contains(processingStatus.toLowerCase());

  @override
  List<Object?> get props => [
    id,
    type,
    contentType,
    uploadStatus,
    processingStatus,
    sizeBytes,
    qcPassed,
    qcReason,
    durationSeconds,
    qualityScore,
    createdAt,
    uploadedAt,
  ];
}

/// `view` of `XrayUploadRequest`.
enum XrayView {
  pa('PA', 'PA'),
  ap('AP', 'AP'),
  lateral('lateral', 'Lateral'),
  other('other', 'Other');

  const XrayView(this.api, this.label);
  final String api;
  final String label;

  static XrayView? fromApi(String? v) {
    for (final x in values) {
      if (x.api == v) return x;
    }
    return null;
  }
}

/// `XrayOut`.
class XrayImage extends Equatable {
  const XrayImage({
    required this.id,
    required this.contentType,
    required this.uploadStatus,
    this.fileName,
    this.sizeBytes,
    this.view,
    this.takenOn,
    this.notes,
    this.uploadedAt,
  });

  final String id;
  final String contentType;
  final String uploadStatus;
  final String? fileName;
  final int? sizeBytes;
  final XrayView? view;
  final DateTime? takenOn;
  final String? notes;
  final DateTime? uploadedAt;

  bool get isUploaded =>
      uploadedAt != null ||
      const {'uploaded', 'complete', 'completed'}.contains(uploadStatus);

  @override
  List<Object?> get props => [
    id,
    contentType,
    uploadStatus,
    fileName,
    sizeBytes,
    view,
    takenOn,
    notes,
    uploadedAt,
  ];
}

/// A file on this device, ready to upload.
class LocalFile extends Equatable {
  const LocalFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.contentType,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String contentType;

  @override
  List<Object?> get props => [path, name, sizeBytes, contentType];
}

/// Fractional upload progress, 0–1.
typedef UploadProgress = void Function(double fraction);
