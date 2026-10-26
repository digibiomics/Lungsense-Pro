import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../authentication/presentation/widgets/role_page.dart';

/// 29 Admin · users (AdminUsers.dc.html).
///
/// Not wired: the API documents no endpoint to list or search users, and
/// `PATCH /admin/users/{user_id}/status` has no documented body or allowed
/// values (KI-02). Suspend/Reactivate stays off rather than guessing.
class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RolePage(
      eyebrow: 'Admin',
      title: 'Users',
      children: [
        const LsEmptyState(
          icon: Icons.manage_accounts_outlined,
          title: 'User management isn\'t available yet',
          body:
              'Searching users and suspending or reactivating accounts will '
              'be enabled once the server\'s user-status service is '
              'confirmed.',
        ),
        const SizedBox(height: LsSpace.md),
        Text(
          'Suspended users can\'t sign in. Their submitted data stays in the '
          'study.',
          textAlign: TextAlign.center,
          style: LsText.helper,
        ),
      ],
    );
  }
}
