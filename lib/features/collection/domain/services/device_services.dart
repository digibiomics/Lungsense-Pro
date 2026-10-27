import '../entities/recording.dart';

/// Microphone capture. The implementation writes AAC in an M4A container
/// (`audio/mp4`) to a temporary file.
abstract interface class AudioCapture {
  /// Asks for microphone access if needed. False when the user refused.
  Future<bool> ensurePermission();

  Future<void> start();

  /// Input level, 0 (silence) to 1 (loud), while recording.
  Stream<double> get level;

  /// Stops and returns the file, or null if nothing was recorded.
  Future<LocalFile?> stop();

  /// Stops and deletes the file.
  Future<void> cancel();

  Future<void> dispose();
}

/// Reads the duration of a local audio file (import validation).
abstract interface class AudioInspector {
  /// Null when the file can't be read as audio.
  Future<Duration?> durationOf(LocalFile file);
}

/// Plays a local file or a download URL.
abstract interface class AudioPlayback {
  Stream<bool> get playing;
  Future<void> playFile(String path);
  Future<void> playUrl(Uri url);
  Future<void> stop();
  Future<void> dispose();
}

/// System file picker.
abstract interface class FilePicking {
  /// An audio file, or null when cancelled.
  Future<LocalFile?> pickAudio();

  /// A JPEG, PNG or DICOM image, or null when cancelled.
  Future<LocalFile?> pickXray();
}

/// Opens a download link outside the app (X-ray "View").
abstract interface class LinkOpener {
  Future<bool> open(Uri url);
}
