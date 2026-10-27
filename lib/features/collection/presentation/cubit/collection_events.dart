import 'dart:async';

/// App-wide notice that a session changed on the server (a step saved, an
/// upload finished, a session was created or submitted). Lists and the
/// overview reload when they hear it, so no screen shows stale progress.
class CollectionEvents {
  final _controller = StreamController<String>.broadcast();

  /// Ids of sessions that changed.
  Stream<String> get changes => _controller.stream;

  void changed(String sessionId) {
    if (!_controller.isClosed) _controller.add(sessionId);
  }

  Future<void> dispose() => _controller.close();
}
