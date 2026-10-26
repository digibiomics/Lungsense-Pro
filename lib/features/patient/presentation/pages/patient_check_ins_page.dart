import 'package:flutter/material.dart';

import '../../../../core/widgets/ls_components.dart';
import '../../../authentication/presentation/widgets/role_page.dart';

/// 26 Patient · my check-ins (PatientHistory.dc.html). History comes from
/// the collection API, which is not part of the documented contract yet.
class PatientCheckInsPage extends StatelessWidget {
  const PatientCheckInsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePage(
      title: 'My check-ins',
      children: [
        LsEmptyState(
          icon: Icons.history,
          title: 'No check-ins yet',
          body:
              'When check-ins are available, each one you submit will appear '
              'here with its date and status.',
        ),
      ],
    );
  }
}
