import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ls_text_field.dart';
import '../../../authentication/domain/entities/registration.dart';

class DoctorProfileFormController {
  final formKey = GlobalKey<FormState>();
  final license = TextEditingController();
  final specialty = TextEditingController();
  final institution = TextEditingController();
  final city = TextEditingController();
  final country = TextEditingController();
  final phone = TextEditingController();
  final notes = TextEditingController();

  DoctorProfileInput? validateAndBuild() {
    if (!(formKey.currentState?.validate() ?? false)) return null;
    return DoctorProfileInput(
      licenseNumber: license.text.trim(),
      specialty: specialty.text.trim(),
      institution: institution.text.trim(),
      city: city.text.trim(),
      country: country.text.trim(),
      phone: phone.text.trim(),
      credentialNotes: notes.text.trim(),
    );
  }

  void dispose() {
    for (final c in [
      license,
      specialty,
      institution,
      city,
      country,
      phone,
      notes,
    ]) {
      c.dispose();
    }
  }
}

/// Doctor profile fields from RegisterDoctor.dc.html. Used by email sign-up
/// and by the Google account-type step.
class DoctorProfileForm extends StatelessWidget {
  const DoctorProfileForm({
    super.key,
    required this.controller,
    required this.enabled,
    required this.fieldErrors,
    required this.showCredentialNotes,
    this.onChanged,
  });

  final DoctorProfileFormController controller;
  final bool enabled;
  final Map<String, String> fieldErrors;
  final bool showCredentialNotes;
  final VoidCallback? onChanged;

  static const fieldNames = {
    'license_number',
    'specialty',
    'institution',
    'city',
    'country',
    'phone',
    'credential_notes',
  };

  @override
  Widget build(BuildContext context) {
    final c = controller;
    Widget field(
      String key,
      String label,
      TextEditingController ctrl,
      String? Function(String?)? validator, {
      TextInputType? keyboard,
      List<String>? autofill,
    }) => LsTextField(
      fieldKey: Key('doc_$key'),
      label: label,
      controller: ctrl,
      enabled: enabled,
      keyboardType: keyboard,
      autofillHints: autofill,
      textInputAction: TextInputAction.next,
      errorText: fieldErrors[key],
      validator: validator,
      onChanged: (_) => onChanged?.call(),
    );

    return Form(
      key: c.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(
            'license_number',
            'Medical licence number',
            c.license,
            Validators.required('Enter your licence number.'),
          ),
          const SizedBox(height: 14),
          field(
            'specialty',
            'Specialty',
            c.specialty,
            Validators.required('Enter your specialty.'),
          ),
          const SizedBox(height: 14),
          field(
            'institution',
            'Hospital or institution',
            c.institution,
            Validators.required('Enter your hospital or institution.'),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              final city = field(
                'city',
                'City',
                c.city,
                Validators.required('Enter a city.'),
                autofill: const [AutofillHints.addressCity],
              );
              final country = field(
                'country',
                'Country',
                c.country,
                Validators.required('Enter a country.'),
                autofill: const [AutofillHints.countryName],
              );
              // Two columns as designed; stack on narrow screens.
              if (box.maxWidth < 300) {
                return Column(
                  children: [city, const SizedBox(height: 14), country],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: city),
                  const SizedBox(width: LsSpace.sm),
                  Expanded(child: country),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          field(
            'phone',
            'Phone',
            c.phone,
            Validators.phone,
            keyboard: TextInputType.phone,
            autofill: const [AutofillHints.telephoneNumber],
          ),
          if (showCredentialNotes) ...[
            const SizedBox(height: 14),
            LsTextField(
              fieldKey: const Key('doc_credential_notes'),
              label: 'Credential notes (optional)',
              controller: c.notes,
              enabled: enabled,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              helperText: 'Anything that helps the research team verify you.',
              errorText: fieldErrors['credential_notes'],
              onChanged: (_) => onChanged?.call(),
            ),
          ],
        ],
      ),
    );
  }
}
