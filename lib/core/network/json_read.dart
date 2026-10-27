import '../errors/failure.dart';

/// Small helpers for reading the documented JSON schemas
/// (docs/openapi_snapshot.json) without code generation. Required fields
/// that are missing or of the wrong type throw [JsonRead.unexpected] so a
/// changed contract shows an error instead of fabricated data.
abstract final class JsonRead {
  static Failure unexpected(String what) => Failure(
    kind: FailureKind.unknown,
    message: 'The $what came back in an unexpected format.',
  );

  static Map<String, dynamic> map(Object? v, String what) {
    if (v is Map) return v.cast<String, dynamic>();
    throw unexpected(what);
  }

  static String? str(Object? v) => switch (v) {
    final String s => s,
    final num n => n.toString(),
    _ => null,
  };

  static String reqStr(Map<String, dynamic> m, String key, String what) =>
      str(m[key]) ?? (throw unexpected(what));

  static int? integer(Object? v) => switch (v) {
    final int i => i,
    final num n => n.toInt(),
    _ => null,
  };

  static double? number(Object? v) => v is num ? v.toDouble() : null;

  static bool? boolean(Object? v) => v is bool ? v : null;

  static DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;

  static List<Object?> list(Object? v) => v is List ? v : const [];

  /// `Page[T]`: `{items, total, limit, offset}`.
  static ({List<T> items, int total}) page<T>(
    Object? json,
    T Function(Object? item) item,
    String what,
  ) {
    final m = map(json, what);
    final raw = m['items'];
    if (raw is! List) throw unexpected(what);
    final items = raw.map(item).toList();
    return (items: items, total: integer(m['total']) ?? items.length);
  }
}
