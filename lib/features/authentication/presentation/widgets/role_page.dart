import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/session_outcome.dart';
import '../cubit/session_cubit.dart';

/// The signed-in user, or null while the session is changing.
AppUser? currentUser(BuildContext context) {
  final s = context.watch<SessionCubit>().state;
  return switch (s) {
    SessionResolved(outcome: Authenticated(:final user)) => user,
    _ => null,
  };
}

/// Header + scrollable body used by every tab in the role areas.
/// [eyebrow] is the small line above the title (date, "Admin").
class RolePage extends StatelessWidget {
  const RolePage({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
    this.trailing,
    this.onRefresh,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(
        LsSpace.gutter,
        LsSpace.xs,
        LsSpace.gutter,
        LsSpace.xl,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null)
                          Text(
                            eyebrow!,
                            style: LsText.helper.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Semantics(
                          header: true,
                          child: Text(title, style: LsText.screenTitle),
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            Expanded(
              child: onRefresh == null
                  ? list
                  : RefreshIndicator(
                      color: AppColors.supportingGreen,
                      onRefresh: onRefresh!,
                      child: list,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Monday, 26 October" without the intl package.
String formatLongDate(DateTime d) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
}

String greetingFor(DateTime d) => d.hour < 12
    ? 'Good morning'
    : d.hour < 17
    ? 'Good afternoon'
    : 'Good evening';

String firstName(AppUser u) {
  final n = u.fullName?.trim();
  if (n == null || n.isEmpty) return '';
  return n.split(RegExp(r'\s+')).first;
}
