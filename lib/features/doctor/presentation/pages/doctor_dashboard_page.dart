import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../authentication/presentation/widgets/role_shell.dart';

/// 10 Doctor dashboard: reachable only for an active, approved doctor.
/// Patients and sessions (Dashboard.dc.html) are built in milestone M4.
class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      title: 'Dashboard',
      roleLabel: 'Doctor',
      children: [
        Text(
          'Your patients and collection sessions will appear here.',
          style: LsText.subtitle,
        ),
      ],
    );
  }
}
