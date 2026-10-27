import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_search_field.dart';
import '../../../admin/presentation/widgets/application_widgets.dart';
import '../../../patients/domain/entities/patient.dart';
import '../../../patients/presentation/cubit/patient_cubits.dart';
import '../../../patients/presentation/pages/patients_page.dart';
import '../../domain/entities/recording.dart';
import '../cubit/list_cubits.dart';

/// 16 Start collection: choose a patient (StartCollection.dc.html).
class StartCollectionPage extends StatefulWidget {
  const StartCollectionPage({super.key, this.patientId, this.studyId});

  /// Preselected from Patient detail.
  final String? patientId;
  final String? studyId;

  @override
  State<StartCollectionPage> createState() => _StartCollectionPageState();
}

class _StartCollectionPageState extends State<StartCollectionPage> {
  late String? _pickId = widget.patientId;
  late String? _pickStudy = widget.studyId;

  Future<void> _start(BuildContext context) async {
    final id = _pickId;
    if (id == null) return;
    final s = await context.read<StartSessionCubit>().start(patientId: id);
    if (s != null && context.mounted) {
      context.pushReplacement(Routes.doctorSessionFor(s.id));
    }
  }

  Future<void> _register(BuildContext context) async {
    final p = await context.push<Patient>(Routes.doctorAddPatient);
    if (p != null && mounted) {
      setState(() {
        _pickId = p.id;
        _pickStudy = p.studyId;
      });
      if (context.mounted) await context.read<PatientsCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = context.watch<StartSessionCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('New collection')),
      body: BlocBuilder<PatientsCubit, PatientsState>(
        builder: (context, state) {
          final cubit = context.read<PatientsCubit>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              LsSpace.gutter,
              LsSpace.xs,
              LsSpace.gutter,
              LsSpace.lg,
            ),
            children: [
              Text('Which patient?', style: LsText.screenTitle),
              const SizedBox(height: 4),
              Text(
                'The session is linked to this patient\'s ID.',
                style: LsText.subtitle,
              ),
              const SizedBox(height: LsSpace.md),
              LsSearchField(
                fieldKey: const Key('start_search'),
                hint: 'Search patients',
                onChanged: cubit.search,
              ),
              const SizedBox(height: LsSpace.md),
              Text(
                state.query.trim().isEmpty ? 'Recent patients' : 'Results',
                style: LsText.label,
              ),
              const SizedBox(height: LsSpace.xs),
              if (state.loading && state.items.isEmpty)
                const SkeletonList()
              else if (state.failure != null)
                LsBanner(
                  tone: LsBannerTone.error,
                  title: 'Couldn\'t load patients.',
                  body: FailureMessages.generic(state.failure!).body,
                  actionLabel: 'Try again',
                  onAction: cubit.load,
                )
              else if (state.items.isEmpty)
                Text('No patients found.', style: LsText.helper)
              else
                LsPanel(
                  children: [
                    for (final p in state.items.where((p) => !p.isArchived))
                      PatientRow(
                        patient: p,
                        selected: _pickId == p.id,
                        onTap: () => setState(() {
                          final on = _pickId == p.id;
                          _pickId = on ? null : p.id;
                          _pickStudy = on ? null : p.studyId;
                        }),
                      ),
                  ],
                ),
              const SizedBox(height: LsSpace.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: LsLinkButton(
                  key: const Key('start_register'),
                  label: 'Register a new patient',
                  onPressed: () => _register(context),
                ),
              ),
              const SizedBox(height: LsSpace.md),
              LsNote(
                bordered: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This session includes · about 3 min',
                      style: LsText.label,
                    ),
                    const SizedBox(height: 6),
                    for (final line in [
                      'Cough recording · ${RecordingType.cough.min}–'
                          '${RecordingType.cough.max} s',
                      'Breathing recording · ${RecordingType.breathing.min}–'
                          '${RecordingType.breathing.max} s',
                      'Symptom severity, 0–3',
                      'Clinical context (optional)',
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('· $line'),
                      ),
                  ],
                ),
              ),
              if (start.failure != null) ...[
                const SizedBox(height: LsSpace.md),
                LsBanner(
                  tone: LsBannerTone.error,
                  title: 'Session not started.',
                  body:
                      start.failure!.message ??
                      FailureMessages.generic(start.failure!).body,
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(
            LsSpace.gutter,
            LsSpace.sm,
            LsSpace.gutter,
            LsSpace.md,
          ),
          child: LsButton(
            key: const Key('start_session'),
            label: _pickId == null
                ? 'Select a patient to start'
                : 'Start session for ${_pickStudy ?? 'this patient'}',
            loading: start.starting,
            loadingLabel: 'Starting…',
            onPressed: _pickId == null ? null : () => _start(context),
          ),
        ),
      ),
    );
  }
}
