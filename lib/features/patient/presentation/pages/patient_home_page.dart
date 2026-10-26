import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../authentication/presentation/widgets/role_page.dart';

/// 25 Patient home (PatientHome.dc.html). The check-in itself needs the
/// collection API, which is not documented yet, so the card explains that
/// instead of starting a fake session.
class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key, this.now});

  /// Injectable clock for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final user = currentUser(context);
    final today = now ?? DateTime.now();
    final name = user == null ? '' : firstName(user);
    return RolePage(
      eyebrow: formatLongDate(today),
      title: name.isEmpty ? 'Hello' : 'Hello, $name',
      trailing: user == null
          ? null
          : Semantics(
              button: true,
              label: 'Profile',
              child: GestureDetector(
                onTap: () => context.go(Routes.patientProfile),
                child: LsAvatar(name: user.displayName),
              ),
            ),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(LsRadius.hero),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Today\'s check-in', style: LsText.section),
                  ),
                  const LsStatusPill(
                    label: 'Not available yet',
                    tone: LsPillTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final (icon, label) in const [
                (Icons.mic_none_outlined, 'Cough recording'),
                (Icons.air, 'Breathing recording'),
                (Icons.checklist, 'Symptoms'),
              ]) ...[
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: LsTint.iconDisc,
                        borderRadius: BorderRadius.circular(LsRadius.small),
                      ),
                      child: Icon(icon, size: 18, color: AppColors.text),
                    ),
                    const SizedBox(width: LsSpace.sm),
                    Expanded(child: Text(label, style: LsText.bodySmall)),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              const LsButton(
                label: 'Start check-in · about 3 min',
                onPressed: null,
              ),
              const SizedBox(height: 8),
              Text(
                'Check-ins open once your study\'s recording service is '
                'connected to this app.',
                textAlign: TextAlign.center,
                style: LsText.helper,
              ),
            ],
          ),
        ),
        const SizedBox(height: LsSpace.lg),
        Text('Recent check-ins', style: LsText.section),
        const SizedBox(height: 10),
        const LsEmptyState(
          icon: Icons.history,
          title: 'No check-ins yet',
          body: 'Your submitted check-ins will be listed here.',
        ),
        const SizedBox(height: LsSpace.lg),
        Text(
          'Your recordings are used for research only. This app does not '
          'diagnose or give medical advice.',
          textAlign: TextAlign.center,
          style: LsText.footnote,
        ),
      ],
    );
  }
}
