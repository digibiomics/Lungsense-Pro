import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../domain/entities/doctor_application.dart';

LsStatusPill statusPill(AccountStatus s) => switch (s) {
  AccountStatus.pendingApproval => const LsStatusPill(
    label: 'Pending approval',
    tone: LsPillTone.pending,
  ),
  AccountStatus.active => const LsStatusPill(
    label: 'Active',
    tone: LsPillTone.success,
  ),
  AccountStatus.rejected => const LsStatusPill(
    label: 'Rejected',
    tone: LsPillTone.error,
  ),
  AccountStatus.suspended => const LsStatusPill(
    label: 'Suspended',
    tone: LsPillTone.error,
  ),
  AccountStatus.deactivated => const LsStatusPill(
    label: 'Deactivated',
    tone: LsPillTone.error,
  ),
  AccountStatus.unknown => const LsStatusPill(
    label: 'Status unknown',
    tone: LsPillTone.neutral,
  ),
};

String applicationMeta(DoctorApplication a) {
  final p = a.doctorProfile;
  final place = [
    p?.institution,
    p?.city,
  ].where((v) => v != null && v.isNotEmpty).join(', ');
  return [
    p?.specialty,
    place,
  ].where((v) => v != null && v.isNotEmpty).join(' · ');
}

String shortDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = d.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

/// Placeholder rows while loading (States.dc.html skeleton).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 3});
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: LsPanel(
        children: [
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _bar(44, 44, circle: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(140, 14),
                        const SizedBox(height: 8),
                        _bar(200, 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(double w, double h, {bool circle = false}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(circle ? h / 2 : 4),
    ),
  );
}
