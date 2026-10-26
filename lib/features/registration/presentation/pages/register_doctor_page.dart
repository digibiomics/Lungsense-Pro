import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_screen.dart';
import '../../../authentication/domain/entities/registration.dart';
import '../cubit/registration_cubit.dart';
import '../widgets/doctor_profile_form.dart';
import '../widgets/registration_error_banner.dart';

/// 05 Sign up · doctor details (RegisterDoctor.dc.html).
class RegisterDoctorPage extends StatefulWidget {
  const RegisterDoctorPage({super.key});

  @override
  State<RegisterDoctorPage> createState() => _RegisterDoctorPageState();
}

class _RegisterDoctorPageState extends State<RegisterDoctorPage> {
  final _form = DoctorProfileFormController();

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final profile = _form.validateAndBuild();
    if (profile == null) return;
    context.read<RegistrationCubit>().submit(doctorProfile: profile);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationCubit, RegistrationState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == RegistrationStatus.succeeded) {
          context.go(Routes.verifyEmailFor(state.email, doctor: true));
        }
      },
      builder: (context, state) {
        return LsScreen(
          onBack: () => context.pop(),
          headerTrailing: const LsStepLabel('Step 3 of 3 · Doctor'),
          bottomDivider: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Professional details', style: LsText.authTitle),
              const SizedBox(height: 6),
              Text(
                'The research team uses these to verify and approve your '
                'account.',
                style: LsText.subtitle,
              ),
              RegistrationErrorBanner(
                state: state,
                handledFields: DoctorProfileForm.fieldNames,
              ),
              const SizedBox(height: 22),
              DoctorProfileForm(
                controller: _form,
                enabled: !state.submitting,
                fieldErrors: state.fieldErrors,
                showCredentialNotes: true,
                onChanged: context.read<RegistrationCubit>().clearError,
              ),
            ],
          ),
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LsButton(
                key: const Key('doctor_submit'),
                label: 'Create account',
                loadingLabel: 'Creating account…',
                loading: state.submitting,
                onPressed: state.accountType == AccountType.doctor
                    ? _submit
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Approval usually follows email confirmation.',
                textAlign: TextAlign.center,
                style: LsText.helper,
              ),
            ],
          ),
        );
      },
    );
  }
}
