import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../authentication/presentation/widgets/role_shell.dart';

/// 25 Patient home: authenticated entry point. Check-ins (PatientHome.dc.html)
/// are built in milestone M4 once the collection APIs are confirmed.
class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      title: 'Home',
      roleLabel: 'Patient',
      children: [
        Text('Your check-ins will appear here.', style: LsText.subtitle),
      ],
    );
  }
}
