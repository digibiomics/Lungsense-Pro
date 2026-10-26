import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../authentication/presentation/widgets/role_page.dart';

/// 10 Doctor dashboard (Dashboard.dc.html). Reached only by an active,
/// approved doctor. Patients, drafts and activity need the collection API
/// (not documented yet), so the empty state is shown.
class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final user = currentUser(context);
    final t = now ?? DateTime.now();
    return RolePage(
      eyebrow: formatLongDate(t),
      title: user == null
          ? greetingFor(t)
          : '${greetingFor(t)}, ${user.displayName}',
      trailing: user == null
          ? null
          : Semantics(
              button: true,
              label: 'Profile',
              child: GestureDetector(
                onTap: () => context.go(Routes.doctorProfile),
                child: LsAvatar(name: user.displayName),
              ),
            ),
      children: [
        const LsButton(
          label: 'Start new collection',
          icon: Icon(Icons.add, size: 20),
          height: 56,
          onPressed: null,
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a patient, then record cough and breathing.',
          textAlign: TextAlign.center,
          style: LsText.helper,
        ),
        const SizedBox(height: LsSpace.lg),
        const LsEmptyState(
          icon: Icons.folder_open_outlined,
          title: 'No collections yet',
          body:
              'Patient registration and data collection open once the '
              'collection service is connected to this app. Your sessions '
              'will appear here.',
        ),
      ],
    );
  }
}
