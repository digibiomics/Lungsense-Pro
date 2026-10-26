import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/ls_bottom_nav.dart';

/// Bottom-navigation shell for one role (LsBottomNav from the handoff).
class RoleScaffold extends StatelessWidget {
  const RoleScaffold({super.key, required this.shell, required this.items});

  final StatefulNavigationShell shell;
  final List<LsNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: LsBottomNav(
        items: items,
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

abstract final class RoleNavItems {
  static const patient = [
    LsNavItem(Icons.home_outlined, 'Home'),
    LsNavItem(Icons.history, 'Check-ins'),
    LsNavItem(Icons.person_outline, 'Profile'),
  ];
  static const doctor = [
    LsNavItem(Icons.home_outlined, 'Home'),
    LsNavItem(Icons.groups_outlined, 'Patients'),
    LsNavItem(Icons.event_note_outlined, 'Sessions'),
    LsNavItem(Icons.person_outline, 'Profile'),
  ];
  static const admin = [
    LsNavItem(Icons.verified_user_outlined, 'Approvals'),
    LsNavItem(Icons.manage_accounts_outlined, 'Users'),
    LsNavItem(Icons.person_outline, 'Profile'),
  ];
}
