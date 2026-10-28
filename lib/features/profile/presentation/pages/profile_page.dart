import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_info.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/presentation/cubit/session_cubit.dart';
import '../../../authentication/presentation/widgets/role_page.dart';

/// 15 Profile (Profile.dc.html), shared by all roles. Data comes from
/// `GET /users/me`; pull to refresh re-reads it. Editing is not offered
/// because no profile-update endpoint is documented. Patients also get
/// [details] (their own record, which they can edit).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.details});

  /// Shown under the account details.
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final user = currentUser(context);
    final session = context.read<SessionCubit>();

    Future<void> refresh() async {
      final failure = await session.refreshUser();
      if (failure != null && context.mounted) {
        final copy = FailureMessages.generic(failure);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${copy.title} ${copy.body}')));
      }
    }

    if (user == null) return const RolePage(title: 'Profile', children: []);

    final (String roleLabel, String detailsTitle) = switch (user.role) {
      UserRole.doctor => ('Approved doctor', 'Doctor details'),
      UserRole.admin => ('Administrator', 'Account details'),
      _ => ('Patient', 'Account details'),
    };
    final dp = user.doctorProfile;
    final rows = <(String, String?)>[
      ('Email', user.email),
      if (user.role == UserRole.doctor) ...[
        ('Licence no.', dp?.licenseNumber),
        ('Specialty', dp?.specialty),
        (
          'Institution',
          [
            dp?.institution,
            dp?.city,
            dp?.country,
          ].where((v) => v != null && v.isNotEmpty).join(', '),
        ),
        ('Phone', dp?.phone),
      ],
      if (user.role == UserRole.patient) ('Study ID', user.patientStudyId),
    ].where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();

    return RolePage(
      title: 'Profile',
      onRefresh: refresh,
      children: [
        Row(
          children: [
            LsAvatar(name: user.displayName, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: LsText.section),
                  const SizedBox(height: 4),
                  LsStatusPill(label: roleLabel, tone: LsPillTone.success),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: LsSpace.lg),
        Text(detailsTitle, style: LsText.section),
        const SizedBox(height: 10),
        LsPanel(
          children: [
            for (final (k, v) in rows) LsKeyValueRow(label: k, value: v!),
          ],
        ),
        if (details != null) ...[const SizedBox(height: LsSpace.lg), details!],
        const SizedBox(height: LsSpace.lg),
        Text('Account', style: LsText.section),
        const SizedBox(height: 10),
        LsPanel(
          children: [
            ListTile(
              key: const Key('profile_change_password'),
              minTileHeight: 52,
              contentPadding: const EdgeInsets.only(left: 16, right: 12),
              title: Text('Change password', style: LsText.bodySmall),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: () => context.push(Routes.forgotPasswordFor(user.email)),
            ),
          ],
        ),
        const SizedBox(height: LsSpace.lg),
        SizedBox(
          height: LsSize.input,
          child: OutlinedButton.icon(
            key: const Key('sign_out'),
            onPressed: session.signOut,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              textStyle: LsText.bodySmall.copyWith(fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LsRadius.control),
              ),
            ),
          ),
        ),
        const SizedBox(height: LsSpace.lg),
        Text(
          'LungSense Pro · version ${AppInfo.version}\n'
          'For research data collection only. Not a diagnostic tool.',
          textAlign: TextAlign.center,
          style: LsText.footnote,
        ),
      ],
    );
  }
}
