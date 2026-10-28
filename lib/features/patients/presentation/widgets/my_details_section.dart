import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../domain/entities/patient.dart';
import '../cubit/patient_cubits.dart';
import '../pages/patient_detail_page.dart';

/// "My details" on a patient's Profile: their own record (`GET
/// /patients/me`) and an Edit link to the details form.
class MyDetailsSection extends StatelessWidget {
  const MyDetailsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyRecordCubit, MyRecordState>(
      builder: (context, state) {
        final cubit = context.read<MyRecordCubit>();
        final p = state.patient;
        final history = p?.relevantHistory?.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('My details', style: LsText.section)),
                if (p != null)
                  TextButton(
                    key: const Key('my_details_edit'),
                    onPressed: () async {
                      final updated = await context.push<Patient>(
                        Routes.patientDetails,
                      );
                      if (updated != null) cubit.applyUpdate(updated);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.supportingGreen,
                    ),
                    child: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (p != null &&
                patientRecordFacts(p).isEmpty &&
                (history == null || history.isEmpty))
              Text('No details yet. Add them with Edit.', style: LsText.helper)
            else if (p != null)
              LsFactGrid(
                key: const Key('my_details_facts'),
                facts: patientRecordFacts(p),
                wide: [
                  if (history != null && history.isNotEmpty)
                    ('Relevant history', history),
                ],
              )
            else if (state.failure != null)
              LsBanner(
                tone: LsBannerTone.error,
                title: 'Couldn\'t load your details.',
                body: FailureMessages.generic(state.failure!).body,
                actionLabel: 'Try again',
                onAction: cubit.load,
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.supportingGreen,
                ),
              ),
          ],
        );
      },
    );
  }
}
