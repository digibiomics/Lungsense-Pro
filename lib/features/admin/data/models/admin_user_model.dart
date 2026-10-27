import '../../../../core/network/json_read.dart';
import '../../../../core/utils/paged.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../domain/entities/admin_user.dart';

/// Parser for `AdminUserOut` and `Page[AdminUserOut]`.
abstract final class AdminUserModel {
  static const _what = 'user list';

  static Paged<AdminUser> pageFromJson(Object? json) {
    final p = JsonRead.page(json, fromJson, _what);
    return Paged(items: p.items, total: p.total);
  }

  static AdminUser fromJson(Object? json) {
    final m = JsonRead.map(json, _what);
    return AdminUser(
      id: JsonRead.reqStr(m, 'id', _what),
      email: JsonRead.reqStr(m, 'email', _what),
      fullName: JsonRead.str(m['full_name']),
      role: UserRole.fromApi(JsonRead.str(m['role'])),
      status: AccountStatus.fromApi(JsonRead.str(m['account_status'])),
      createdAt: JsonRead.date(m['created_at']),
    );
  }
}
