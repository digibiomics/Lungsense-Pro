import '../entities/collection_session.dart';

/// Ids of drafts the user removed on this device.
abstract interface class HiddenDraftsStore {
  Future<Set<String>> read();
  Future<void> write(Set<String> ids);
}

/// Keeps ids in memory only (tests, or when device storage fails).
class MemoryHiddenDraftsStore implements HiddenDraftsStore {
  Set<String> _ids = {};

  @override
  Future<Set<String>> read() async => {..._ids};

  @override
  Future<void> write(Set<String> ids) async => _ids = {...ids};
}

/// Which drafts the app still offers to resume.
///
/// The API has no way to delete or cancel a session (KI-25), so both rules
/// only hide drafts in this app; the server keeps them as drafts:
/// - a draft the user removed ([hide]);
/// - a draft not finished on the day it started ([isExpired]).
class DraftVisibility {
  DraftVisibility(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final HiddenDraftsStore _store;
  final DateTime Function() _clock;
  Set<String>? _hidden;

  /// Most removed ids kept; older ones are long expired anyway.
  static const maxKept = 500;

  /// A draft started before today (local time). Drafts without a start
  /// time stay visible.
  static bool isExpired(SessionSummary s, DateTime now) {
    final t = s.startedAt?.toLocal();
    if (!s.isDraft || t == null) return false;
    final n = now.toLocal();
    return DateTime(
      t.year,
      t.month,
      t.day,
    ).isBefore(DateTime(n.year, n.month, n.day));
  }

  Future<Set<String>> _load() async => _hidden ??= await _store.read();

  /// [items] without removed or expired drafts. Submitted sessions always
  /// stay.
  Future<List<SessionSummary>> visible(List<SessionSummary> items) async {
    final hidden = await _load();
    final now = _clock();
    return [
      for (final s in items)
        if (!s.isDraft || (!hidden.contains(s.id) && !isExpired(s, now))) s,
    ];
  }

  /// Removes a draft from this device's lists.
  Future<void> hide(String sessionId) async {
    final ids = [...await _load(), sessionId];
    final kept = ids.length > maxKept ? ids.sublist(ids.length - maxKept) : ids;
    _hidden = kept.toSet();
    await _store.write(_hidden!);
  }
}
