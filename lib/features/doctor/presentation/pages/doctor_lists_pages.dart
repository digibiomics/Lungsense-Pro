import 'package:flutter/material.dart';

import '../../../../core/widgets/ls_components.dart';
import '../../../authentication/presentation/widgets/role_page.dart';

/// 11 Patient list (Patients.dc.html). Needs the patient API (not yet
/// documented); shows the empty state until it is connected.
class DoctorPatientsPage extends StatelessWidget {
  const DoctorPatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePage(
      title: 'Patients',
      children: [
        LsEmptyState(
          icon: Icons.groups_outlined,
          title: 'No patients yet',
          body:
              'Patients you register will be listed here once the patient '
              'service is connected to this app.',
        ),
      ],
    );
  }
}

/// 14 Collection history (Sessions.dc.html).
class DoctorSessionsPage extends StatelessWidget {
  const DoctorSessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePage(
      title: 'Sessions',
      children: [
        LsEmptyState(
          icon: Icons.event_note_outlined,
          title: 'No sessions yet',
          body:
              'Draft and submitted collection sessions will appear here once '
              'the collection service is connected to this app.',
        ),
      ],
    );
  }
}
