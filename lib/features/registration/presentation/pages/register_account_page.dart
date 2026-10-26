import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_screen.dart';
import '../../../../core/widgets/ls_text_field.dart';
import '../../../authentication/domain/entities/registration.dart';
import '../cubit/registration_cubit.dart';
import '../widgets/registration_error_banner.dart';

/// 04 Sign up · account (Register.dc.html). Patients submit from here;
/// doctors continue to professional details.
class RegisterAccountPage extends StatefulWidget {
  const RegisterAccountPage({super.key});

  @override
  State<RegisterAccountPage> createState() => _RegisterAccountPageState();
}

class _RegisterAccountPageState extends State<RegisterAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late final RegistrationState _initial = context
      .read<RegistrationCubit>()
      .state;
  late final _name = TextEditingController(text: _initial.fullName);
  late final _email = TextEditingController(text: _initial.email);
  late final _password = TextEditingController(text: _initial.password);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _continue(RegistrationState state) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<RegistrationCubit>()
      ..saveAccount(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
      );
    if (state.isDoctor) {
      cubit.clearError();
      context.push(Routes.signUpDoctor);
    } else {
      cubit.submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationCubit, RegistrationState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == RegistrationStatus.succeeded && !state.isDoctor) {
          context.go(Routes.verifyEmailFor(state.email, doctor: false));
        }
      },
      builder: (context, state) {
        final cubit = context.read<RegistrationCubit>();
        final role = state.isDoctor ? 'Doctor' : 'Patient';
        final errors = state.fieldErrors;
        return LsScreen(
          onBack: () => context.pop(),
          headerTrailing: LsStepLabel('Step 2 of ${state.totalSteps} · $role'),
          bottomDivider: true,
          body: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Your account', style: LsText.authTitle),
                  const SizedBox(height: 6),
                  Text(
                    'You\'ll use these details to sign in.',
                    style: LsText.subtitle,
                  ),
                  if (!state.isDoctor)
                    RegistrationErrorBanner(
                      state: state,
                      handledFields: const {'full_name', 'email', 'password'},
                    ),
                  const SizedBox(height: LsSpace.lg),
                  LsTextField(
                    fieldKey: const Key('reg_name'),
                    label: 'Full name',
                    controller: _name,
                    enabled: !state.submitting,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    errorText: errors['full_name'],
                    validator: Validators.required('Enter your full name.'),
                    onChanged: (_) => cubit.clearError(),
                  ),
                  const SizedBox(height: LsSpace.md),
                  LsTextField(
                    fieldKey: const Key('reg_email'),
                    label: 'Email address',
                    controller: _email,
                    enabled: !state.submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    highlightError: state.duplicate,
                    errorText: errors['email'],
                    validator: Validators.email,
                    onChanged: (_) => cubit.clearError(),
                  ),
                  const SizedBox(height: LsSpace.md),
                  LsTextField(
                    fieldKey: const Key('reg_password'),
                    label: 'Password',
                    controller: _password,
                    obscure: true,
                    enabled: !state.submitting,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    helperText:
                        'Use a strong password. If it doesn\'t meet the '
                        'server\'s rules, we\'ll show why here.',
                    errorText: errors['password'],
                    validator: Validators.newPassword,
                    onChanged: (_) => cubit.clearError(),
                  ),
                  const SizedBox(height: LsSpace.md),
                  LsCheckboxTile(
                    key: const Key('reg_consent'),
                    value: state.consent,
                    onChanged: state.submitting ? (_) {} : cubit.setConsent,
                    child: const Text(
                      'I agree to the research data protocol and to audio '
                      'recordings being stored for research.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottom: LsButton(
            key: const Key('reg_continue'),
            label: !state.consent
                ? 'Agree to the terms to continue'
                : state.accountType == AccountType.doctor
                ? 'Continue'
                : 'Create account',
            loadingLabel: 'Creating account…',
            loading: state.submitting,
            onPressed: state.consent ? () => _continue(state) : null,
          ),
        );
      },
    );
  }
}
