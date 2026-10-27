import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/recording.dart';
import '../../domain/services/device_services.dart';

/// Content type for a picked file, from its extension.
String contentTypeFor(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'm4a' || 'mp4' => 'audio/mp4',
    'aac' => 'audio/aac',
    'wav' => 'audio/wav',
    'mp3' => 'audio/mpeg',
    'ogg' => 'audio/ogg',
    'webm' => 'audio/webm',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'dcm' || 'dicom' => 'application/dicom',
    _ => 'application/octet-stream',
  };
}

/// [AudioCapture] with the `record` package: AAC-LC, mono, 44.1 kHz, M4A.
class RecordAudioCapture implements AudioCapture {
  final AudioRecorder _recorder = AudioRecorder();
  final _level = StreamController<double>.broadcast();
  StreamSubscription<Amplitude>? _amp;
  String? _path;

  @override
  Stream<double> get level => _level.stream;

  @override
  Future<bool> ensurePermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/ls_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _path = path;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: path,
    );
    _amp = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((a) {
          // dBFS (-60..0) to 0..1.
          final v = ((a.current + 60) / 60).clamp(0.0, 1.0);
          _level.add(math.pow(v, 1.5).toDouble());
        });
  }

  @override
  Future<LocalFile?> stop() async {
    await _amp?.cancel();
    _amp = null;
    final path = await _recorder.stop() ?? _path;
    if (path == null) return null;
    final f = File(path);
    if (!f.existsSync()) return null;
    return LocalFile(
      path: path,
      name: f.uri.pathSegments.last,
      sizeBytes: await f.length(),
      contentType: 'audio/mp4',
    );
  }

  @override
  Future<void> cancel() async {
    await _amp?.cancel();
    _amp = null;
    await _recorder.cancel();
  }

  @override
  Future<void> dispose() async {
    await _amp?.cancel();
    await _level.close();
    await _recorder.dispose();
  }
}

/// [AudioInspector] that asks the platform player for the duration.
class JustAudioInspector implements AudioInspector {
  @override
  Future<Duration?> durationOf(LocalFile file) async {
    final player = AudioPlayer();
    try {
      return await player.setFilePath(file.path);
    } catch (_) {
      return null;
    } finally {
      await player.dispose();
    }
  }
}

class JustAudioPlayback implements AudioPlayback {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<bool> get playing => _player.playerStateStream.map(
    (s) => s.playing && s.processingState != ProcessingState.completed,
  );

  @override
  Future<void> playFile(String path) async {
    await _player.setFilePath(path);
    unawaited(_player.play());
  }

  @override
  Future<void> playUrl(Uri url) async {
    await _player.setUrl(url.toString());
    unawaited(_player.play());
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class SystemFilePicking implements FilePicking {
  @override
  Future<LocalFile?> pickAudio() => _pick(FileType.audio);

  @override
  Future<LocalFile?> pickXray() => _pick(
    FileType.custom,
    extensions: const ['jpg', 'jpeg', 'png', 'dcm', 'dicom'],
  );

  Future<LocalFile?> _pick(FileType type, {List<String>? extensions}) async {
    final f = await FilePicker.pickFile(
      type: type,
      allowedExtensions: extensions,
    );
    final path = f?.path ?? f?.xFile.path;
    if (f == null || path == null || path.isEmpty) return null;
    return LocalFile(
      path: path,
      name: f.name,
      sizeBytes: await f.length() ?? await File(path).length(),
      contentType: contentTypeFor(f.name),
    );
  }
}

class ExternalLinkOpener implements LinkOpener {
  @override
  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}
