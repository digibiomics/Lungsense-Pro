import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../authentication/presentation/widgets/role_shell.dart';

/// 27 Admin: reachable only for an active admin. Doctor approvals and user
/// status management (AdminDoctors / AdminReview / AdminUsers) are built in
/// milestone M5 after the admin response schemas are confirmed.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      title: 'Approvals',
      roleLabel: 'Administrator',
      children: [
        Text(
          'Doctor applications awaiting review will appear here.',
          style: LsText.subtitle,
        ),
      ],
    );
  }
}
