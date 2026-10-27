import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_text_field.dart';
import '../../domain/entities/patient.dart';
import '../cubit/patient_cubits.dart';

/// 12 Add patient (AddPatient.dc.html); also "Edit" from Patient detail.
///
/// Collects the design's fields (hospital reference, age, sex, notes) plus
/// research consent, which the API records (`consent_status`). No names or
/// contact details. Pops with the saved [Patient].
class PatientFormPage extends StatefulWidget {
  const PatientFormPage({super.key});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _form = GlobalKey<FormState>();
  final _ref = TextEditingController();
  final _age = TextEditingController();
  final _notes = TextEditingController();
  PatientSex? _sex;
  bool _consent = false;
  bool _tried = false;
  bool _seeded = false;

  @override
  void dispose() {
    _ref.dispose();
    _age.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _seed(Patient p) {
    _seeded = true;
    _ref.text = p.externalId ?? '';
    _age.text = p.ageYears?.toString() ?? '';
    _notes.text = p.relevantHistory ?? '';
    _sex = p.sex == PatientSex.unknown ? null : p.sex;
    _consent = p.consent == ConsentStatus.given;
  }

  PatientInput? _input(PatientFormState state) {
    setState(() => _tried = true);
    final ok = _form.currentState?.validate() ?? false;
    if (!ok || _sex == null) return null;
    final previous = state.initial?.consent;
    return PatientInput(
      externalId: _ref.text.trim(),
      ageYears: int.parse(_age.text.trim()),
      sex: _sex!,
      // Unticking never claims "withdrawn"; it keeps the server's value
      // unless consent had been given.
      consent: _consent
          ? ConsentStatus.given
          : (previous == ConsentStatus.given
                ? ConsentStatus.withdrawn
                : (previous ?? ConsentStatus.notRecorded)),
      relevantHistory: _notes.text,
    );
  }

  Future<void> _submit(
    PatientFormCubit cubit,
    PatientFormState state, {
    bool allowDuplicate = false,
  }) async {
    final input = _input(state);
    if (input == null) return;
    await cubit.submit(input, allowDuplicate: allowDuplicate);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PatientFormCubit>();
    return BlocConsumer<PatientFormCubit, PatientFormState>(
      listener: (context, state) {
        if (!_seeded && state.initial != null) {
          setState(() => _seed(state.initial!));
        }
        if (state.phase == PatientFormPhase.saved && state.saved != null) {
          context.pop(state.saved);
        }
      },
      builder: (context, state) {
        final saving = state.phase == PatientFormPhase.saving;
        final errors = state.fieldErrors;
        final dup = state.duplicate;
        final title = cubit.editing ? 'Edit patient' : 'New patient';
        if (cubit.editing && state.initial == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: state.loadFailure == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.supportingGreen,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(LsSpace.gutter),
                    child: LsBanner(
                      tone: LsBannerTone.error,
                      title: 'Couldn\'t load this patient.',
                      body: FailureMessages.generic(state.loadFailure!).body,
                      actionLabel: 'Try again',
                      onAction: cubit.loadInitial,
                    ),
                  ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: TextButton(
              onPressed: saving ? null : () => context.pop(),
              child: const Text('Cancel'),
            ),
            leadingWidth: 88,
          ),
          body: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                LsSpace.gutter,
                LsSpace.xs,
                LsSpace.gutter,
                LsSpace.lg,
              ),
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Fields marked '),
                      TextSpan(
                        text: '*',
                        style: LsText.label.copyWith(color: AppColors.error),
                      ),
                      const TextSpan(
                        text:
                            ' are required. Avoid entering names or contact '
                            'details.',
                      ),
                    ],
                  ),
                  style: LsText.helper,
                ),
                const SizedBox(height: LsSpace.md),
                if (dup != null) ...[
                  LsBanner(
                    tone: LsBannerTone.warning,
                    title: dup.matches.isEmpty
                        ? 'This patient may already be registered.'
                        : 'A patient with reference ${_ref.text.trim()} is '
                              'already registered as '
                              '${dup.matches.map((m) => m.studyId ?? 'another record').join(', ')}.',
                    body: dup.matches.isEmpty ? dup.message : null,
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        if (dup.matches.isNotEmpty &&
                            dup.matches.first.id != null)
                          LsLinkButton(
                            label: 'Open existing patient',
                            onPressed: () => context.pushReplacement(
                              Routes.doctorPatientFor(dup.matches.first.id!),
                            ),
                          ),
                        LsLinkButton(
                          key: const Key('patient_save_anyway'),
                          label: 'Save as a new patient anyway',
                          onPressed: () =>
                              _submit(cubit, state, allowDuplicate: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LsSpace.md),
                ],
                if (state.failure != null && errors.isEmpty) ...[
                  LsBanner(
                    tone: LsBannerTone.error,
                    title: 'Patient not saved.',
                    body: FailureMessages.generic(state.failure!).body,
                  ),
                  const SizedBox(height: LsSpace.md),
                ],
                LsTextField(
                  label: 'Hospital reference number *',
                  fieldKey: const Key('patient_ref'),
                  controller: _ref,
                  enabled: !saving,
                  highlightError: dup != null,
                  errorText: errors['external_id'],
                  helperText:
                      'Used to avoid registering the same patient twice.',
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter the hospital reference number.'
                      : null,
                ),
                const SizedBox(height: LsSpace.md),
                LsTextField(
                  label: 'Age in years *',
                  fieldKey: const Key('patient_age'),
                  controller: _age,
                  enabled: !saving,
                  errorText: errors['age_years'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null) return 'Enter the age in years.';
                    if (n > 130) return 'Enter an age from 0 to 130.';
                    return null;
                  },
                ),
                const SizedBox(height: LsSpace.md),
                Text('Sex *', style: LsText.label),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final s in const [
                      PatientSex.male,
                      PatientSex.female,
                      PatientSex.other,
                    ]) ...[
                      if (s != PatientSex.male) const SizedBox(width: 8),
                      Expanded(
                        child: _SexOption(
                          sex: s,
                          selected: _sex == s,
                          onTap: saving ? null : () => setState(() => _sex = s),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_tried && _sex == null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Choose the patient\'s sex.',
                    style: LsText.helper.copyWith(color: AppColors.error),
                  ),
                ] else if (errors['sex'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    errors['sex']!,
                    style: LsText.helper.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: LsSpace.md),
                LsTextField(
                  label: 'Notes (optional)',
                  fieldKey: const Key('patient_notes'),
                  controller: _notes,
                  enabled: !saving,
                  maxLines: 4,
                  errorText: errors['relevant_history'],
                  inputFormatters: [LengthLimitingTextInputFormatter(5000)],
                ),
                const SizedBox(height: LsSpace.md),
                LsCheckboxTile(
                  key: const Key('patient_consent'),
                  value: _consent,
                  onChanged: (v) {
                    if (!saving) setState(() => _consent = v);
                  },
                  child: const Text(
                    'The patient has given consent to take part in the '
                    'research study.',
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                LsSpace.gutter,
                LsSpace.sm,
                LsSpace.gutter,
                LsSpace.md,
              ),
              child: LsButton(
                key: const Key('patient_save'),
                label: 'Save patient',
                loading: saving,
                loadingLabel: 'Saving…',
                onPressed: () => _submit(cubit, state),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SexOption extends StatelessWidget {
  const _SexOption({
    required this.sex,
    required this.selected,
    required this.onTap,
  });

  final PatientSex sex;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? LsTint.chosen : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LsRadius.control),
          side: BorderSide(
            color: selected ? AppColors.supportingGreen : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          key: Key('patient_sex_${sex.api}'),
          borderRadius: BorderRadius.circular(LsRadius.control),
          onTap: onTap,
          child: SizedBox(
            height: LsSize.input,
            child: Center(
              child: Text(
                sex.label,
                style: LsText.label.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
