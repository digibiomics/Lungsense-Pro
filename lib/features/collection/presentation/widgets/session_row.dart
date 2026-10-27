import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/collection_session.dart';
import 'collection_widgets.dart';

/// "2 of 3 required steps" for drafts, "X-ray included / not added" when
/// completed (Sessions.dc.html).
String sessionProgressNote(SessionSummary s, {bool patient = false}) {
  if (s.isDraft) {
    final left = 3 - s.counts.requiredDone;
    return patient
        ? (left == 0
              ? 'All steps done · ready to submit'
              : '$left step${left == 1 ? '' : 's'} left')
        : '${s.counts.requiredDone} of 3 required steps';
  }
  return s.counts.xrays > 0 ? 'X-ray included' : 'X-ray not added';
}

/// Session list row: title, status pill, meta line, Resume/Finish link.
class SessionRow extends StatelessWidget {
  const SessionRow({
    super.key,
    required this.session,
    required this.title,
    required this.onTap,
    this.patient = false,
    this.now,
  });

  final SessionSummary session;
  final String title;
  final VoidCallback onTap;
  final bool patient;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final t = s.startedAt;
    final meta = [
      if (t != null) LsDates.time(t),
      sessionProgressNote(s, patient: patient),
    ].join(' · ');
    return InkWell(
      key: Key('session_${s.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: LsText.listTitle),
                      sessionPill(s.status, patient: patient),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(meta, style: LsText.helper),
                ],
              ),
            ),
            if (s.isDraft)
              Text(
                patient ? 'Finish' : 'Resume',
                style: LsText.label.copyWith(
                  color: AppColors.supportingGreen,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
