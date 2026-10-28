import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/services/draft_visibility.dart';

/// [HiddenDraftsStore] in secure storage, next to the session tokens. If
/// the platform store fails, ids are kept for this run only.
class SecureHiddenDraftsStore implements HiddenDraftsStore {
  SecureHiddenDraftsStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final _fallback = MemoryHiddenDraftsStore();

  static const key = 'lungsense_pro.collection.hidden_drafts';

  @override
  Future<Set<String>> read() async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return {};
      final list = jsonDecode(raw);
      return list is List ? {for (final v in list) '$v'} : {};
    } on Object {
      return _fallback.read();
    }
  }

  @override
  Future<void> write(Set<String> ids) async {
    await _fallback.write(ids);
    try {
      await _storage.write(key: key, value: jsonEncode(ids.toList()));
    } on Object {
      // Kept in memory for this run.
    }
  }
}
