import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/brand.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/session_outcome.dart';
import '../cubit/session_cubit.dart';

/// Minimal authenticated frame used by the role home screens until their
/// full designs (Dashboard, PatientHome, AdminDoctors) are built.
/// Reached only after the backend has confirmed role and status.
class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.title,
    required this.roleLabel,
    required this.children,
  });

  final String title;
  final String roleLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SessionCubit>().state;
    final user = switch (state) {
      SessionResolved(outcome: Authenticated(:final user)) => user,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: LsSize.headerHeight,
        titleSpacing: LsSpace.gutter,
        automaticallyImplyLeading: false,
        title: LsWordmark(
          style: LsText.listTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('sign_out'),
            onPressed: () => context.read<SessionCubit>().signOut(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(LsSize.minTouch, LsSize.minTouch),
              textStyle: LsText.label.copyWith(fontWeight: FontWeight.w600),
            ),
            child: const Text('Sign out'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LsSpace.gutter),
          children: [
            Text(title, style: LsText.screenTitle),
            const SizedBox(height: 4),
            if (user != null)
              Text('Signed in as ${user.displayName}', style: LsText.helper),
            const SizedBox(height: LsSpace.lg),
            if (user != null) _AccountCard(user: user, roleLabel: roleLabel),
            const SizedBox(height: LsSpace.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.roleLabel});
  final AppUser user;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(k, style: LsText.helper)),
          Expanded(child: Text(v, style: LsText.label)),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(LsRadius.panel),
      ),
      child: Column(
        children: [
          row('Email', user.email),
          row('Role', roleLabel),
          row('Status', 'Active'),
        ],
      ),
    );
  }
}
