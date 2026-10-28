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

/// 12 Add patient (AddPatient.dc.html); also "Edit" from Patient detail and,
/// with [PatientFormCubit.mine], the patient's own "My details".
///
/// Collects full name, age, gender (the API's `sex`), smoking status, height,
/// weight and relevant history. Doctors also enter the hospital reference and
/// research consent (`consent_status`). Pops with the saved [Patient].
class PatientFormPage extends StatefulWidget {
  const PatientFormPage({super.key});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _form = GlobalKey<FormState>();
  final _ref = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _notes = TextEditingController();
  PatientSex? _sex;
  SmokingStatus? _smoking;
  bool _consent = false;
  bool _tried = false;
  bool _seeded = false;

  @override
  void dispose() {
    _ref.dispose();
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _seed(Patient p) {
    _seeded = true;
    _ref.text = p.externalId ?? '';
    _name.text = p.fullName ?? '';
    _age.text = p.ageYears?.toString() ?? '';
    _height.text = _numberText(p.heightCm);
    _weight.text = _numberText(p.weightKg);
    _notes.text = p.relevantHistory ?? '';
    _sex = p.sex == PatientSex.unknown ? null : p.sex;
    _smoking = p.smokingStatus == SmokingStatus.unknown
        ? null
        : p.smokingStatus;
    _consent = p.consent == ConsentStatus.given;
  }

  static String _numberText(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  static double? _parseNumber(String text) => double.tryParse(text.trim());

  /// Optional measurement: blank, or a number above 0 and up to [max].
  static String? _checkMeasure(String? v, double max, String what) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    if (n == null || n <= 0 || n > max) {
      return 'Enter $what above 0 and up to ${max.toInt()}.';
    }
    return null;
  }

  PatientInput? _input(PatientFormState state, bool self) {
    setState(() => _tried = true);
    final ok = _form.currentState?.validate() ?? false;
    if (!ok || _sex == null || _smoking == null) return null;
    final previous = state.initial?.consent;
    return PatientInput(
      fullName: _name.text.trim(),
      ageYears: int.parse(_age.text.trim()),
      sex: _sex!,
      smokingStatus: _smoking!,
      heightCm: _parseNumber(_height.text),
      weightKg: _parseNumber(_weight.text),
      relevantHistory: _notes.text,
      externalId: self ? null : _ref.text.trim(),
      // Unticking never claims "withdrawn"; it keeps the server's value
      // unless consent had been given. Patients record consent on Home.
      consent: self
          ? null
          : _consent
          ? ConsentStatus.given
          : (previous == ConsentStatus.given
                ? ConsentStatus.withdrawn
                : (previous ?? ConsentStatus.notRecorded)),
    );
  }

  Future<void> _submit(
    PatientFormCubit cubit,
    PatientFormState state, {
    bool allowDuplicate = false,
  }) async {
    final input = _input(state, cubit.self);
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
        final self = cubit.self;
        final title = self
            ? 'My details'
            : (cubit.editing ? 'Edit patient' : 'New patient');
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
                      title: self
                          ? 'Couldn\'t load your details.'
                          : 'Couldn\'t load this patient.',
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
                      const TextSpan(text: ' are required.'),
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
                    title: self ? 'Details not saved.' : 'Patient not saved.',
                    body: FailureMessages.generic(state.failure!).body,
                  ),
                  const SizedBox(height: LsSpace.md),
                ],
                if (!self) ...[
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
                ],
                LsTextField(
                  label: 'Full name *',
                  fieldKey: const Key('patient_name'),
                  controller: _name,
                  enabled: !saving,
                  errorText: errors['full_name'],
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter the full name.'
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
                _ChoiceField<PatientSex>(
                  label: 'Gender *',
                  keyPrefix: 'patient_sex',
                  options: const [
                    PatientSex.male,
                    PatientSex.female,
                    PatientSex.other,
                  ],
                  value: _sex,
                  labelOf: (s) => s.label,
                  apiOf: (s) => s.api,
                  onChanged: saving ? null : (s) => setState(() => _sex = s),
                  error: _tried && _sex == null
                      ? 'Choose the gender.'
                      : errors['sex'],
                ),
                const SizedBox(height: LsSpace.md),
                _ChoiceField<SmokingStatus>(
                  label: 'Smoking status *',
                  keyPrefix: 'patient_smoking',
                  options: const [
                    SmokingStatus.never,
                    SmokingStatus.former,
                    SmokingStatus.current,
                  ],
                  value: _smoking,
                  labelOf: (s) => s.label,
                  apiOf: (s) => s.api,
                  onChanged: saving
                      ? null
                      : (s) => setState(() => _smoking = s),
                  error: _tried && _smoking == null
                      ? 'Choose the smoking status.'
                      : errors['smoking_status'],
                ),
                const SizedBox(height: LsSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LsTextField(
                        label: 'Height in cm',
                        fieldKey: const Key('patient_height'),
                        controller: _height,
                        enabled: !saving,
                        errorText: errors['height_cm'],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (v) => _checkMeasure(v, 300, 'a height'),
                      ),
                    ),
                    const SizedBox(width: LsSpace.sm),
                    Expanded(
                      child: LsTextField(
                        label: 'Weight in kg',
                        fieldKey: const Key('patient_weight'),
                        controller: _weight,
                        enabled: !saving,
                        errorText: errors['weight_kg'],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (v) => _checkMeasure(v, 500, 'a weight'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LsSpace.md),
                LsTextField(
                  label: 'Relevant history',
                  fieldKey: const Key('patient_notes'),
                  controller: _notes,
                  enabled: !saving,
                  maxLines: 4,
                  errorText: errors['relevant_history'],
                  inputFormatters: [LengthLimitingTextInputFormatter(5000)],
                ),
                if (!self) ...[
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
                label: self ? 'Save details' : 'Save patient',
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

/// A required single choice shown as a row of equal buttons.
class _ChoiceField<T> extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.keyPrefix,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.apiOf,
    required this.onChanged,
    this.error,
  });

  final String label;
  final String keyPrefix;
  final List<T> options;
  final T? value;
  final String Function(T) labelOf;
  final String Function(T) apiOf;
  final ValueChanged<T>? onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: LsText.label),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final o in options) ...[
              if (o != options.first) const SizedBox(width: 8),
              Expanded(
                child: _ChoiceOption(
                  optionKey: Key('${keyPrefix}_${apiOf(o)}'),
                  label: labelOf(o),
                  selected: value == o,
                  onTap: onChanged == null ? null : () => onChanged!(o),
                ),
              ),
            ],
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: LsText.helper.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }
}

class _ChoiceOption extends StatelessWidget {
  const _ChoiceOption({
    required this.optionKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key optionKey;
  final String label;
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
          key: optionKey,
          borderRadius: BorderRadius.circular(LsRadius.control),
          onTap: onTap,
          child: SizedBox(
            height: LsSize.input,
            child: Center(
              child: Text(
                label,
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
